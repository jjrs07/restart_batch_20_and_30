# Securing a Web Application with AWS Certificate Manager (ACM), Application Load Balancer, and HTTPS

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 60–90 minutes<br>
**Format:** Independent, self-paced AWS Management Console activity<br>
**Region:** `us-east-2` (Ohio)

> **IMPORTANT:** Complete this lab only in an AWS sandbox or account where you
> are authorized to create billable resources. The Application Load Balancer,
> EC2 instance, storage, and public IPv4 addresses can incur charges. Complete
> the cleanup section as soon as you finish.

This activity follows the cycle:

```text
Learn -> Build -> Break -> Troubleshoot -> Document -> Repeat
```

---

## 1. Lab Overview

In this lab, you will build a small web application on an Amazon Linux 2023 EC2
instance. You will place an internet-facing Application Load Balancer (ALB) in
front of the instance, request a public SSL/TLS certificate from AWS Certificate
Manager (ACM), prove control of a public DNS name, and enable HTTPS.

You will first make the application work through the ALB with HTTP. You will then
add HTTPS, point a hostname to the ALB, redirect HTTP to HTTPS, intentionally
break several components, and use evidence to diagnose each failure.

The ACM certificate will be attached to the ALB. It will **not** be installed on
the EC2 instance in this lab.

---

## 2. Learning Objectives

By the end of this lab, you will be able to:

1. Explain what AWS Certificate Manager does.
2. Request a public ACM certificate in the correct AWS Region.
3. Validate control of a public DNS name with a CNAME record.
4. Interpret ACM certificate states such as `Pending validation` and `Issued`.
5. Attach an ACM certificate to an ALB HTTPS listener on port `443`.
6. Configure an ALB HTTP listener to redirect port `80` traffic to HTTPS.
7. Explain TLS termination at an Application Load Balancer.
8. Restrict an EC2 web server to traffic from the ALB security group.
9. Test DNS, target health, HTTP, HTTPS, and certificate hostname matching.
10. Troubleshoot common certificate, DNS, listener, and security-group failures.

---

## 3. Architecture

```text
                         Internet
                            |
                            v
                  +-------------------+
                  | Public DNS name   |
                  | app.example.com   |
                  +-------------------+
                            |
                            v
             +--------------------------------+
             | Application Load Balancer      |
             | HTTP :80 / HTTPS :443           |
             | ACM certificate attached here  |
             +--------------------------------+
                            |
                            | HTTP :80
                            v
                    +---------------+
                    | Target Group  |
                    | Health: /     |
                    +---------------+
                            |
                            | HTTP :80
                            v
                    +---------------+
                    | EC2 Web       |
                    | Server        |
                    | Apache :80    |
                    +---------------+
```

### TLS termination

```text
Browser
   |
   | HTTPS: encrypted connection
   v
Application Load Balancer
   |  decrypts the request here
   |
   | HTTP: unencrypted lab back-end connection
   v
EC2 web server
```

The client checks the certificate presented by the ALB and establishes an
encrypted HTTPS connection with the ALB. The ALB decrypts the request and sends
HTTP to the EC2 target. This is called **TLS termination** or **TLS offloading**.

The target group may use HTTP because the certificate protects the client-to-ALB
connection. This keeps the lab simple. For production systems with compliance or
end-to-end encryption requirements, use HTTPS between the ALB and targets as
well, install certificates on the targets, and validate the complete design.

> **Remember this:** ACM manages the certificate lifecycle, but another AWS
> service—an ALB in this lab—actually presents and uses the certificate.

---

## 4. Prerequisites

You need:

- An AWS account or provided AWS lab environment.
- Permission to create and delete EC2 instances, security groups, target groups,
  load balancers, listeners, and ACM certificates.
- Permission to create DNS records if you use Amazon Route 53.
- A public domain or subdomain whose DNS records you can manage.
- A computer with a web browser and an SSH client.
- Basic familiarity with EC2, VPC subnets, and security groups.
- Two public subnets in different Availability Zones for the ALB. The default
  VPC normally provides suitable subnets, but verify their route tables include
  a route to an internet gateway.

> **IMPORTANT:** ACM public certificates require a publicly resolvable domain or
> subdomain that you control. A private hostname, an EC2 public DNS name, and the
> ALB's AWS-generated DNS name are not substitutes for your own DNS name.

> **NOTE:** Some managed AWS learning environments block ACM, Route 53, ELB, IAM,
> or public-domain operations. Check the lab account restrictions before you
> begin. If the required services are blocked, document the restriction and ask
> your instructor for an account where the lab is permitted.

### Region rule

Use `us-east-2` for **every AWS resource in this lab**. ACM certificates are
Regional. A certificate requested in another Region will not appear when you
configure the Ohio ALB listener.

### Naming worksheet

Choose a short lab identifier using your initials, for example `js`. Replace
`<id>` in the guide with your value.

| Resource | Suggested name |
|---|---|
| EC2 instance | `<id>-acm-web` |
| EC2 security group | `<id>-acm-web-sg` |
| ALB security group | `<id>-acm-alb-sg` |
| Target group | `<id>-acm-tg` |
| Application Load Balancer | `<id>-acm-alb` |
| Application hostname | `app.<your-domain>` |

Use tags where your account permits them:

| Key | Example value |
|---|---|
| `Project` | `acm-https-lab` |
| `Owner` | your initials |
| `Environment` | `training` |

---

## 5. Estimated Completion Time

Allow approximately **60–90 minutes** after you have access to a usable public
domain or subdomain. DNS propagation or restricted lab permissions can extend
the completion time.

---

## 6. Estimated Cost

The following resources may incur charges while they exist:

- Application Load Balancer running time and Load Balancer Capacity Unit usage.
- Public IPv4 addresses used by the internet-facing ALB.
- The `t3.micro` EC2 instance, its EBS volume, and its public IPv4 address.
- An optional Route 53 public hosted zone and Route 53 DNS queries.
- Domain registration and renewal through your chosen registrar.
- Charges imposed by an external DNS or domain provider.

ACM public certificates used with supported integrated AWS services such as
Elastic Load Balancing are generally provided without an additional certificate
charge. Do **not** request an exportable certificate for this lab; the ALB can use
the standard ACM-managed public certificate directly. Always verify the current
[ACM](https://aws.amazon.com/certificate-manager/pricing/),
[Elastic Load Balancing](https://aws.amazon.com/elasticloadbalancing/pricing/),
[EC2](https://aws.amazon.com/ec2/pricing/), and
[VPC public IPv4](https://aws.amazon.com/vpc/pricing/) pricing for your account.

> **COST CONTROL:** An ALB uses infrastructure in multiple Availability Zones.
> Delete the ALB promptly after the lab instead of leaving it running overnight.

---

## 7. Domain Options

### The concept before the options

The company that registers a domain, the company that hosts its DNS records, and
AWS do not have to be the same provider.

```text
Domain Registrar
      |  records who controls the domain
      v
DNS Provider
      |  publishes DNS records
      v
AWS Certificate Manager
      |  checks the validation CNAME
      v
Application Load Balancer
      |  uses the issued certificate
      v
Web application
```

- The domain does **not** have to be registered with AWS.
- DNS does **not** have to be hosted in Route 53.
- ACM only needs you to prove control of the requested DNS name.
- DNS validation normally uses a CNAME record supplied by ACM.

Simplified validation example:

```text
_acm-validation.example.com
        |
        | CNAME
        v
_random-value.acm-validations.aws
```

The validation CNAME is proof of control. It is different from the application
DNS record that later points `app.example.com` to the ALB.

### Option 1 — Paid domain

This is appropriate if you want to continue cloud labs or build a professional
portfolio. You may purchase an inexpensive domain from any registrar, including:

- Namecheap
- Porkbun
- GoDaddy
- Cloudflare Registrar
- Amazon Route 53 Domains
- Another registrar of your choice

The registrar does not have to be AWS. The only technical requirement for this
lab is that you can manage the public DNS records for the domain or delegate DNS
to a provider where you can manage them.

Before purchasing, check both:

1. The introductory registration price.
2. The renewal price after the introductory period.

Also review taxes, WHOIS privacy, transfer rules, and whether DNS hosting is
included. No particular top-level domain is mandatory for this activity.

### Option 2 — GitHub Student Developer Pack

Eligible students can check the
[GitHub Student Developer Pack](https://education.github.com/pack/) for current
domain offers from participating providers. Offers, eligible domain extensions,
durations, and renewal terms can change. Verify the offer details at the time you
claim it; do not rely on an old screenshot or classroom handout.

### Option 3 — FreeDNS / afraid.org shared subdomain

If you do not want to buy a domain, you may try
[FreeDNS / afraid.org](https://freedns.afraid.org/) and select an available shared
domain or subdomain. FreeDNS supports CNAME records, which are required for this
lab's ACM validation and for pointing an application subdomain at the ALB.

Before building AWS resources, confirm that your selected shared domain lets you:

1. Create a hostname such as `app.your-shared-domain.example`.
2. Create the ACM-provided CNAME whose name begins with an underscore.
3. Keep both CNAME records in public DNS for the duration of the lab.

Shared-domain availability and certificate-authority policies can change. If ACM
cannot issue a certificate for the selected name, choose another available
domain or use a paid/student option. Free shared domains are suitable for labs
but may not provide the branding, ownership, stability, or control expected for
a professional portfolio.

### Domain decision tree

```text
Do you already own a domain?
        |
       YES
        |
        +--> Use an existing domain or subdomain
        |
       NO
        |
        +--> Eligible for GitHub Student Developer Pack?
        |       |
        |       +--> Check and use a current student domain offer
        |
        +--> Want a domain for future projects?
        |       |
        |       +--> Purchase an inexpensive domain
        |
        +--> Lab only?
                |
                +--> Try FreeDNS/shared subdomain
```

### Domain checkpoint

Write down your planned hostname before creating AWS resources:

```text
Base domain or shared domain: ______________________________
Application hostname:       app.____________________________
DNS provider:                ________________________________
Can create CNAME records?    YES / NO
```

> **CHECKPOINT:** Do not continue unless you can sign in to the DNS provider and
> create records for the application hostname.

---

## 8. Part 1 — Launch the Web Server

### Step 1: Select the Region

1. Sign in to the AWS Management Console.
2. In the top navigation bar, select **US East (Ohio) `us-east-2`**.
3. Keep this Region selected for EC2, the ALB, target group, and ACM.

### Step 2: Create the ALB security group

Create the ALB security group before the instance security group so you can use
it as an inbound source.

1. Open **EC2**.
2. In the left navigation pane, choose **Security Groups**.
3. Choose **Create security group**.
4. Configure:

   | Setting | Value |
   |---|---|
   | Security group name | `<id>-acm-alb-sg` |
   | Description | `Internet access for the ACM HTTPS lab ALB` |
   | VPC | The VPC you will use for the entire lab |

5. Add these inbound rules:

   | Type | Protocol | Port | Source | Purpose |
   |---|---|---:|---|---|
   | HTTP | TCP | 80 | `0.0.0.0/0` | Initial HTTP test and later redirect |
   | HTTPS | TCP | 443 | `0.0.0.0/0` | Public HTTPS access |

6. Keep the default outbound rule for this short lab.
7. Add the recommended tags and choose **Create security group**.
8. Copy its security group ID, such as `sg-0123456789abcdef0`.

> **WHY:** The ALB is the public entry point, so its listener ports accept
> internet traffic. The EC2 instance will not accept HTTP directly from the
> internet.

### Step 3: Create the web-server security group

1. Choose **Create security group** again.
2. Configure:

   | Setting | Value |
   |---|---|
   | Security group name | `<id>-acm-web-sg` |
   | Description | `HTTP from ALB and SSH from my IP` |
   | VPC | The same VPC as the ALB security group |

3. Add these inbound rules:

   | Type | Port | Source | Purpose |
   |---|---:|---|---|
   | HTTP | 80 | The `<id>-acm-alb-sg` security group | ALB traffic and health checks |
   | SSH | 22 | **My IP** (`your-public-ip/32`) | Temporary administration |

4. Keep the default outbound rule and create the security group.

> **SECURITY NOTE:** Do not use `0.0.0.0/0` for SSH. Do not expose EC2 port 80
> directly to the internet. Using the ALB security group as the source means the
> instance accepts web traffic from the load balancer, not arbitrary clients.

### Step 4: Launch Amazon Linux 2023

1. In EC2, choose **Instances** and then **Launch instances**.
2. Configure:

   | Setting | Value |
   |---|---|
   | Name | `<id>-acm-web` |
   | AMI | Amazon Linux 2023 AMI, 64-bit x86 |
   | Instance type | `t3.micro` |
   | Key pair | Create or select a lab key pair |
   | VPC | The same VPC used by both security groups |
   | Subnet | A public subnet |
   | Auto-assign public IP | Enabled for this simplified lab |
   | Security group | Select `<id>-acm-web-sg` |
   | Storage | 8 GiB `gp3`, encrypted |

3. Add the recommended tags.
4. Launch the instance.
5. Wait for the instance state to become `Running` and for both status checks to
   pass.

> **TROUBLESHOOTING TIP:** A public subnet requires a route such as
> `0.0.0.0/0 -> igw-...` in its route table. A public IPv4 address alone does not
> make a subnet public.

### Step 5: Connect with SSH

Copy the instance's **Public DNS name**. From Linux, macOS, or WSL:

```bash
chmod 400 <your-key>.pem
ssh -i <your-key>.pem ec2-user@<EC2-PUBLIC-DNS>
```

From Windows PowerShell:

```powershell
ssh -i .\<your-key>.pem ec2-user@<EC2-PUBLIC-DNS>
```

Replace the placeholders with your actual key filename and EC2 public DNS name.
Amazon Linux 2023 uses `ec2-user` as the default username.

### Step 6: Install and configure Apache

Run these commands on the EC2 instance:

```bash
sudo dnf update -y
sudo dnf install -y httpd
sudo systemctl enable --now httpd
```

- `dnf update` installs current package updates.
- `dnf install httpd` installs Apache HTTP Server.
- `systemctl enable --now` starts Apache now and enables it after reboot.

Create the lab page:

```bash
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AWS ACM HTTPS Lab</title>
</head>
<body>
  <h1>AWS ACM HTTPS Lab</h1>
  <p>This web application is secured using AWS Certificate Manager.</p>
</body>
</html>
EOF
```

The `tee` command writes the HTML file with root permissions. The quoted `EOF`
marker prevents the shell from expanding characters inside the page.

Validate Apache locally:

```bash
sudo systemctl is-active httpd
curl -I http://localhost/
curl http://localhost/
```

Expected evidence includes:

```text
active
HTTP/1.1 200 OK
AWS ACM HTTPS Lab
```

> **CHECKPOINT:** Do not continue until Apache is active and `curl` returns the
> page from `localhost`. Direct access to the EC2 public IP may time out because
> the instance security group intentionally permits HTTP only from the ALB.

---

## 9. Part 2 — Create the Application Load Balancer

### Step 1: Create the target group

1. In the EC2 console, choose **Target Groups**.
2. Choose **Create target group**.
3. Configure:

   | Setting | Value |
   |---|---|
   | Target type | `Instances` |
   | Target group name | `<id>-acm-tg` |
   | Protocol | `HTTP` |
   | Port | `80` |
   | IP address type | `IPv4` |
   | VPC | The lab VPC |
   | Protocol version | `HTTP1` |
   | Health check protocol | `HTTP` |
   | Health check path | `/` |

4. Keep the remaining health-check settings at their defaults.
5. Choose **Next**.
6. Select `<id>-acm-web`, keep port `80`, and choose **Include as pending below**.
7. Confirm the instance appears under **Review targets**.
8. Choose **Create target group**.

> **WHY:** The target group tells the ALB where to send requests and how to test
> whether the web server is healthy enough to receive traffic.

### Step 2: Create the ALB

1. In the EC2 console, choose **Load Balancers**.
2. Choose **Create load balancer**.
3. Under **Application Load Balancer**, choose **Create**.
4. Configure:

   | Setting | Value |
   |---|---|
   | Name | `<id>-acm-alb` |
   | Scheme | `Internet-facing` |
   | IP address type | `IPv4` |
   | VPC | The lab VPC |
   | Availability Zones | At least two public subnets in different AZs |
   | Security group | `<id>-acm-alb-sg` only |

5. Under **Listeners and routing**, configure the initial listener:

   | Protocol | Port | Default action |
   |---|---:|---|
   | HTTP | 80 | Forward to `<id>-acm-tg` |

6. Review the configuration and choose **Create load balancer**.
7. Wait until the load balancer state becomes `Active`.

> **IMPORTANT:** An ALB requires subnets in at least two Availability Zones even
> though this simplified lab has only one EC2 target.

### Step 3: Confirm target health

1. Open **Target Groups** and select `<id>-acm-tg`.
2. Open the **Targets** tab.
3. Wait for `<id>-acm-web` to become `Healthy`.

If the target is unhealthy, check these items before changing anything:

1. Apache is active: `sudo systemctl status httpd --no-pager`.
2. `curl -I http://localhost/` returns `200 OK` on EC2.
3. The instance is registered on port `80`.
4. The target group's health check path is `/`.
5. The EC2 security group permits port `80` from the ALB security group.
6. The target group and instance use the same VPC as the ALB.

### Step 4: Test HTTP through the ALB

1. Open the ALB details page.
2. Copy its **DNS name**, similar to:

   ```text
   js-acm-alb-123456789.us-east-2.elb.amazonaws.com
   ```

3. Browse to:

   ```text
   http://<ALB-DNS-NAME>
   ```

4. Confirm the `AWS ACM HTTPS Lab` page loads.

> **CHECKPOINT:** Do not continue until the application loads through the ALB
> using HTTP. HTTPS will not fix an unhealthy target or broken HTTP listener.

Record evidence:

```text
ALB DNS name: _______________________________________________
Target status: HEALTHY / NOT HEALTHY
HTTP test result: ___________________________________________
```

---

## 10. Part 3 — Request the ACM Certificate

1. Confirm the console Region is **US East (Ohio) `us-east-2`**.
2. Open **AWS Certificate Manager**.
3. Choose **Request a certificate**.
4. Choose **Request a public certificate** and continue.
5. Under **Fully qualified domain name**, enter your application hostname:

   ```text
   app.example.com
   ```

   Replace `example.com` with the domain or shared domain you control.

6. Use one specific subdomain for this lab instead of the root domain. A
   subdomain works with standard CNAME records at most external DNS providers.
7. Select **DNS validation**.
8. If the console asks whether the certificate should be exportable, choose the
   standard non-exportable ACM certificate. The private key does not need to
   leave ACM because the ALB is an integrated service.
9. Keep the default key algorithm unless your environment requires another
   supported option. RSA 2048 provides broad client compatibility.
10. Add the recommended tags and choose **Request**.
11. Open the new certificate.

The initial status should be:

```text
Pending validation
```

This does not mean ACM is broken. ACM is waiting for proof that you control the
requested DNS name. Until validation succeeds, the certificate cannot be
attached as an issued certificate to the HTTPS listener.

> **REGION CHECK:** If the certificate was accidentally requested in another
> Region, request the correct certificate in `us-east-2`. Do not build the ALB in
> a second Region to work around the mistake.

---

## 11. Part 4 — DNS Validation

### Understand the two ACM values

In the certificate details, expand the domain entry. ACM provides a record
similar to:

```text
Name:
_abcd1234.app.example.com.

Type:
CNAME

Value:
_xyz987.acm-validations.aws.
```

- **Name** is the DNS label ACM will query.
- **Type** must be `CNAME`.
- **Value** is the AWS-managed validation destination.
- The random strings are unique. Copy the exact values from your certificate.

Do not copy the sample values above into your DNS provider.

### If DNS is hosted in Route 53

If the public hosted zone is in the same AWS account and you have permission:

1. In ACM, choose **Create records in Route 53**.
2. Review the proposed CNAME record.
3. Choose **Create records**.
4. Open Route 53 and confirm the record exists in the **public hosted zone**.

Do not place the validation record only in a private hosted zone. Public ACM
validation must be visible through public DNS.

### If DNS is hosted outside Route 53

These steps apply to Namecheap, Porkbun, GoDaddy, Cloudflare, FreeDNS, and most
other providers. Menu names differ, but the DNS record is the same.

1. Sign in to the provider that hosts your DNS records.
2. Open DNS management for the correct domain.
3. Choose to add a record.
4. Select `CNAME`.
5. Copy the ACM **Name** into the provider's host/name field.
6. Copy the ACM **Value** into the provider's target/value field.
7. Use a short TTL such as `300` seconds if the provider permits it.
8. If the provider offers proxying, use **DNS only** for this learning activity.
9. Save the record.

Some DNS providers automatically append the base domain. If the provider shows
the zone name beside the host field, it may expect only the host portion.

Example for a zone named `example.com`:

```text
ACM full name:     _abcd1234.app.example.com.
Host field may be: _abcd1234.app
```

Entering the full name when the provider appends the domain can create this
incorrect record:

```text
WRONG:
_abcd1234.app.example.com.example.com
```

> **TROUBLESHOOTING TIP:** The validation record name must begin with an
> underscore. Some providers reject a trailing period because they add it
> automatically; in that case, remove only the final period, not the leading
> underscore or random characters.

### Verify the public CNAME

From Windows PowerShell or Command Prompt:

```powershell
nslookup -type=CNAME <ACM-RECORD-NAME>
```

From Linux, macOS, or WSL:

```bash
dig CNAME <ACM-RECORD-NAME> +short
```

The result should contain the ACM value ending in `acm-validations.aws`.

If the result is empty or `NXDOMAIN`:

1. Confirm the record is in the authoritative public DNS zone.
2. Check for a duplicated base domain in the name.
3. Compare every character with the ACM values.
4. Wait for the DNS TTL and propagation.
5. Query a public resolver to avoid a stale local cache:

   ```powershell
   nslookup -type=CNAME <ACM-RECORD-NAME> 8.8.8.8
   ```

ACM checks repeatedly. When validation succeeds, the status changes from:

```text
Pending validation
```

to:

```text
Issued
```

ACM can continue attempting validation for up to 72 hours, but a correct public
record often validates sooner. Do not repeatedly delete and request certificates
while DNS is still propagating.

> **CHECKPOINT:** Do not proceed until the certificate status is `Issued` in
> `us-east-2`.

> **IMPORTANT:** Keep the ACM validation CNAME in DNS while the certificate is in
> use. Removing it does not immediately revoke an issued certificate, but it can
> prevent ACM from validating the domain during automatic renewal.

---

## 12. Part 5 — Configure HTTPS on the ALB

1. Open **EC2** and choose **Load Balancers**.
2. Select `<id>-acm-alb`.
3. Open **Listeners and rules**.
4. Choose **Add listener**.
5. Configure:

   | Setting | Value |
   |---|---|
   | Protocol | `HTTPS` |
   | Port | `443` |
   | Routing action | Forward to target groups |
   | Target group | `<id>-acm-tg` |
   | Security policy | The current console **Recommended** policy |
   | Certificate source | From ACM |
   | Certificate | The `Issued` certificate for `app.<your-domain>` |

6. Confirm the chosen policy supports modern TLS and the clients used in your
   environment. AWS changes its recommended policy over time, so prefer the
   console's current **Recommended** policy rather than copying an old policy
   name from a screenshot.
7. Choose **Add listener**.
8. Confirm the listener list now includes:

   | Protocol | Port | Action |
   |---|---:|---|
   | HTTP | 80 | Forward to `<id>-acm-tg` for now |
   | HTTPS | 443 | Forward to `<id>-acm-tg` |

The request flow is now:

```text
Client -> HTTPS :443 -> ALB -> HTTP :80 -> EC2
```

The ALB presents the ACM certificate, performs the TLS handshake, decrypts the
request, and forwards HTTP to the target. EC2 does not need the ACM certificate
installed locally in this architecture.

> **NOTE:** Do not treat `https://<ALB-DNS-NAME>` as the final certificate test.
> The certificate covers your custom hostname, not the AWS-generated ALB DNS
> name. Browsing directly to the ALB DNS name with HTTPS should produce a
> hostname mismatch.

---

## 13. Part 6 — Point the Domain to the ALB

You now need an **application DNS record**. This is separate from the ACM
validation CNAME.

```text
app.example.com
        |
        | Alias or CNAME
        v
js-acm-alb-123456789.us-east-2.elb.amazonaws.com
```

### Route 53 public hosted zone

1. Open **Route 53**.
2. Open the public hosted zone for your domain.
3. Choose **Create record**.
4. For **Record name**, enter `app`.
5. For **Record type**, select `A`.
6. Enable **Alias**.
7. Choose **Alias to Application and Classic Load Balancer**.
8. Select `us-east-2` and `<id>-acm-alb`.
9. Use **Simple routing** and create the record.

Route 53 returns the ALB's current IP addresses for an alias record and follows
changes to the AWS-managed load balancer addresses.

### External DNS provider

For a subdomain such as `app.example.com`, create a standard CNAME:

| Field | Example |
|---|---|
| Type | `CNAME` |
| Host/name | `app` |
| Target/value | `js-acm-alb-123456789.us-east-2.elb.amazonaws.com` |
| TTL | `300`, if configurable |
| Proxy | DNS only, if the provider offers proxying |

Do not include `http://`, `https://`, a path, or a port in a DNS value.

A standard CNAME normally cannot be used at the root/apex name such as
`example.com`. Some providers offer ALIAS, ANAME, or CNAME flattening at the
apex, but implementations vary. Using `app.example.com` avoids that limitation
and makes this lab portable across DNS providers.

### Verify application DNS

```powershell
nslookup app.example.com
```

or:

```bash
dig app.example.com +short
```

Replace the sample hostname. The lookup should ultimately resolve to public ALB
addresses. It should not resolve to the EC2 public IP.

> **CHECKPOINT:** Confirm that the application hostname resolves toward the ALB
> before testing HTTPS.

---

## 14. Part 7 — Test HTTPS

Browse to your real hostname:

```text
https://app.example.com
```

Verify all of the following:

- The page loads without a browser certificate warning.
- The address bar shows an HTTPS connection.
- The certificate hostname matches the application hostname.
- The certificate issuer is a publicly trusted certificate authority used by
  Amazon.
- The certificate is currently valid.

Use the browser's site-information or certificate viewer to record:

```text
Requested hostname: _________________________________________
Certificate subject/SAN: ____________________________________
Certificate issuer: _________________________________________
Valid from: _______________  Valid until: ____________________
```

Optional command-line test:

```bash
curl -I https://app.example.com
```

Expected evidence includes `HTTP/2 200`, `HTTP/1.1 200 OK`, or another successful
`2xx` response depending on the client and ALB negotiation.

For deeper certificate inspection on a system with OpenSSL:

```bash
openssl s_client -connect app.example.com:443 -servername app.example.com </dev/null
```

The `-servername` option sends Server Name Indication (SNI), allowing the ALB to
select the certificate for the requested hostname.

> **CHECKPOINT:** Do not configure the redirect until HTTPS works directly. If
> HTTPS is broken, redirecting HTTP will send every user into the same failure.

---

## 15. Part 8 — Configure HTTP to HTTPS Redirect

Change the port `80` listener from forwarding to redirecting:

```text
HTTP :80
   |
   +--> HTTP 301 redirect
              |
              v
          HTTPS :443
```

1. Open the ALB's **Listeners and rules** tab.
2. Select the `HTTP:80` listener.
3. Edit its default rule/action.
4. Replace **Forward to** with **Redirect to URL**.
5. Configure:

   | Setting | Value |
   |---|---|
   | Protocol | `HTTPS` |
   | Port | `443` |
   | Host | Preserve the original host (`#{host}` if shown) |
   | Path | Preserve the original path (`/#{path}` if shown) |
   | Query | Preserve the original query (`#{query}` if shown) |
   | Status code | `HTTP_301` |

6. Save the rule.
7. Browse to:

   ```text
   http://app.example.com
   ```

8. Confirm the browser automatically changes the URL to:

   ```text
   https://app.example.com
   ```

Command-line verification:

```bash
curl -I http://app.example.com
```

Expected evidence:

```text
HTTP/1.1 301 Moved Permanently
Location: https://app.example.com/
```

> **WHY:** Port `80` remains reachable only to tell clients to use the secure
> port. Application content is delivered over the HTTPS listener.

---

## 16. Break and Troubleshoot

These scenarios use the disposable lab environment. Record the working value
before changing it, make one change at a time, observe the evidence, and restore
the working configuration before starting the next scenario.

Use this diagnostic order:

```text
1. DNS resolution
      |
2. ALB security group
      |
3. Listener and certificate
      |
4. Target health
      |
5. Apache service and page
```

### Scenario 1 — Remove or modify the ACM validation CNAME

**Break it:** Copy the current validation CNAME to your notes. Delete it or
temporarily change one character in its value. Do not do this if the certificate
or DNS record is shared with a real application.

Test the already-issued website and inspect the certificate in ACM.

Questions:

- Does an already-issued certificate immediately stop working?
- What can happen when ACM later attempts automatic renewal?

<details>
<summary>Hint 1</summary>

Separate certificate issuance from certificate renewal. The certificate already
has a validity period.

</details>

<details>
<summary>Hint 2</summary>

Check whether the certificate is still attached to the HTTPS listener and still
within its validity dates.

</details>

<details>
<summary>Hint 3</summary>

ACM's DNS-based managed renewal requires the validation CNAME to remain publicly
available while the certificate is in use.

</details>

<details>
<summary>Solution</summary>

Deleting the validation CNAME does not immediately revoke an issued certificate,
so the site can continue working until the certificate expires or is replaced.
However, ACM may be unable to prove control during managed renewal. Restore the
exact CNAME and verify it with `nslookup` or `dig`.

</details>

### Scenario 2 — Remove inbound HTTPS from the ALB security group

**Break it:** Remove the inbound TCP `443` rule from `<id>-acm-alb-sg`. Test both
the HTTP and HTTPS URLs.

<details>
<summary>Hint 1</summary>

Use `nslookup` first. If DNS still resolves, move to the network entry point.

</details>

<details>
<summary>Hint 2</summary>

Confirm that an HTTPS listener exists. A listener cannot receive packets that
the ALB security group rejects.

</details>

<details>
<summary>Hint 3</summary>

The HTTP listener may still return a redirect, but the browser then tries port
`443` and times out.

</details>

<details>
<summary>Solution</summary>

Restore inbound HTTPS TCP `443` from `0.0.0.0/0` on the ALB security group. Do
not add this public rule to the EC2 security group.

</details>

### Scenario 3 — Point application DNS away from the ALB

**Break it:** Record the ALB DNS name, then temporarily change the application
CNAME to the reserved non-working target `does-not-exist.invalid`. If you use a
Route 53 alias, temporarily replace or remove the alias only after recording its
configuration.

Run `nslookup` or `dig`, then test the site.

<details>
<summary>Hint 1</summary>

Compare the DNS answer with the ALB DNS name. The certificate and listener can be
healthy while users are sent somewhere else.

</details>

<details>
<summary>Hint 2</summary>

Query a public DNS resolver to separate authoritative DNS from a local cache.

</details>

<details>
<summary>Hint 3</summary>

Wait for the record TTL after changing or restoring DNS.

</details>

<details>
<summary>Solution</summary>

Restore the Route 53 alias or external CNAME so the application hostname points
to the ALB DNS name. Verify public resolution before testing HTTPS again.

</details>

### Scenario 4 — Use a certificate for the wrong hostname

**Break it:** Request and DNS-validate a second standard ACM certificate for
`www.example.com`, replacing the domain with yours. Record the current listener
certificate configuration. On the HTTPS listener, replace the default
certificate with the `www` certificate and ensure the correct `app` certificate
is not still attached in the listener's certificate list. Then visit
`https://app.example.com`.

Do not bypass the browser's certificate warning or enter sensitive information.

<details>
<summary>Hint 1</summary>

Encryption alone is not enough. The browser also verifies identity.

</details>

<details>
<summary>Hint 2</summary>

Compare the URL hostname with the certificate Subject Alternative Names.

</details>

<details>
<summary>Hint 3</summary>

`www.example.com` and `app.example.com` are different names unless both are
listed on the same certificate or covered by an appropriate wildcard.

</details>

<details>
<summary>Solution</summary>

Restore the certificate issued for `app.example.com` as the HTTPS listener's
default certificate. Confirm the browser warning disappears. Remove the second
certificate from the listener, and delete that certificate and its validation
record during cleanup if they were created only for this exercise.

</details>

### Scenario 5 — Remove the HTTPS listener

**Break it:** Record the listener configuration, then delete the `HTTPS:443`
listener from the disposable ALB. Test HTTP and HTTPS.

<details>
<summary>Hint 1</summary>

Security-group permission does not create a listener.

</details>

<details>
<summary>Hint 2</summary>

Check **Listeners and rules** on the ALB.

</details>

<details>
<summary>Hint 3</summary>

The port `80` redirect can still respond, but there is no service accepting the
redirected request on port `443`.

</details>

<details>
<summary>Solution</summary>

Recreate the HTTPS listener on port `443`, select the current recommended
security policy, attach the `Issued` ACM certificate for the application
hostname, and forward to `<id>-acm-tg`.

</details>

### Troubleshooting matrix

| Symptom | Check first | Then check |
|---|---|---|
| `Pending validation` | Public ACM CNAME | Duplicate domain, CAA, DNS propagation |
| Certificate not listed on ALB | ACM Region | Certificate status is `Issued` |
| HTTPS times out | ALB SG port `443` | HTTPS listener and subnet routing |
| Browser hostname warning | URL vs certificate SAN | Correct listener certificate |
| ALB returns `503` | Target health | Apache, EC2 SG, port, health path |
| HTTP works but HTTPS fails | HTTPS listener | Port `443`, certificate, ALB SG |
| Domain does not reach ALB | Application DNS record | DNS target and TTL/cache |

> **TROUBLESHOOTING TIP:** Change only one component at a time. Capture the
> error, form a hypothesis, test it with evidence, and then restore the known
> working state.

---

## 17. Knowledge Check

1. **Multiple choice:** What is ACM's primary role in this architecture?
   - A. Install Apache on EC2
   - B. Provision and manage the TLS certificate
   - C. Create DNS zones automatically at every provider
   - D. Replace the target group

2. **Short answer:** Why must ACM validate the requested domain name?

3. **Multiple choice:** What does `Pending validation` normally mean after a
   DNS-validated certificate request?
   - A. The certificate is already ready for production
   - B. ACM is waiting to find the required public DNS record
   - C. The ALB has failed its health check
   - D. Apache is stopped

4. **Short answer:** Explain TLS termination in this lab.

5. **Troubleshooting:** The certificate is `Issued`, DNS is correct, and HTTP
   works, but TCP port `443` times out. Name two items to inspect.

6. **Multiple choice:** What should the port `80` listener do at the end?
   - A. Forward directly to EC2 over SSH
   - B. Delete all requests
   - C. Redirect clients to HTTPS on port `443`
   - D. Present the ACM certificate on port `80`

7. **Short answer:** Must a domain be registered with AWS or use Route 53 DNS to
   obtain an ACM certificate? Explain.

8. **Multiple choice:** Which record normally proves domain control for ACM DNS
   validation?
   - A. MX
   - B. PTR
   - C. CNAME
   - D. SRV

9. **Troubleshooting:** Why does a certificate for `www.example.com` cause a
   warning at `https://app.example.com`?

10. **Short answer:** Why should the ACM validation CNAME remain after the
    certificate becomes `Issued`?

<details>
<summary>View Answers</summary>

1. **B.** ACM provisions and manages the TLS certificate used by the ALB.
2. A public certificate asserts the identity of a DNS name. ACM must confirm the
   requester controls that name before a trusted certificate authority issues it.
3. **B.** ACM is waiting to discover and verify the required public validation
   record.
4. The browser creates an encrypted HTTPS connection to the ALB. The ALB presents
   the certificate, decrypts the request, and forwards HTTP to the EC2 target.
5. Inspect the ALB security group's inbound `443` rule and the presence/configuration
   of the HTTPS listener. Also verify subnet routing if both appear correct.
6. **C.** It should return an HTTP redirect to HTTPS on port `443`.
7. No. The registrar and DNS provider can be outside AWS. ACM needs a publicly
   resolvable validation record proving control of the requested name.
8. **C.** ACM normally supplies a CNAME for DNS validation.
9. The URL hostname is not covered by the certificate's Subject Alternative Name.
   The browser cannot verify that the server certificate represents `app.example.com`.
10. ACM uses the validation CNAME again during managed renewal. Removing it can
    prevent automatic renewal even though the issued certificate works initially.

</details>

---

## 18. Student Deliverables

Submit the following evidence. Do not expose passwords, private keys, account
numbers, or other secrets in screenshots.

1. Screenshot showing the ACM certificate status as `Issued` and the correct
   Region. You may redact the certificate ID.
2. Screenshot showing the website loaded through the custom HTTPS hostname with
   no certificate warning.
3. Screenshot showing the ALB `HTTPS:443` listener and target-group action.
4. Screenshot showing the DNS validation CNAME. You may redact the random token
   if your instructor allows it, but keep the record type visible.
5. A 3–5 sentence explanation of TLS termination in your own words.
6. A short troubleshooting reflection answering:

   > What problem did you encounter during the lab, and how did you troubleshoot
   > it?

Use this evidence table:

| Evidence | Result or filename |
|---|---|
| ACM `Issued` | |
| HTTPS website | |
| ALB HTTPS listener | |
| DNS validation CNAME | |
| TLS termination explanation | |
| Troubleshooting reflection | |

---

## 19. Cleanup

Remove lab resources in a controlled order. If any resource is shared or existed
before this lab, do not delete it.

1. Restore any deliberately broken settings so you can identify the expected
   resources accurately.
2. Remove the application DNS record (`app.example.com`) created for this lab.
3. In **EC2 > Load Balancers**, delete `<id>-acm-alb`.
4. Wait until the ALB is fully deleted. This releases its AWS-managed public
   addresses and dependencies.
5. In **Target Groups**, delete `<id>-acm-tg`.
6. Terminate `<id>-acm-web`. Confirm it reaches `Terminated` and that its lab EBS
   volume is deleted if **Delete on termination** was enabled.
7. Delete `<id>-acm-web-sg` and `<id>-acm-alb-sg` after their network interfaces
   and references are gone.
8. In ACM `us-east-2`, delete the certificate if it was created only for this lab
   and is no longer associated with an AWS service.
9. Remove the ACM validation CNAME only after deleting the lab certificate. Keep
   it if the certificate will continue to be used and renewed.
10. Delete the optional `www` certificate and validation record from Scenario 4.
11. Delete a Route 53 hosted zone only if you created it solely for this lab and
    it contains no records you need. Hosted zones can incur recurring charges.
12. Delete the lab key pair from EC2 and securely remove the downloaded private
    key if it will not be reused.
13. Check the EC2, Load Balancers, Target Groups, ACM, VPC security groups, EBS
    Volumes, Elastic IPs, and Route 53 pages for unexpected remaining resources.

> **IMPORTANT:** Do **not** delete or cancel a purchased domain unless you truly
> want to give up the registration. Removing lab DNS records is different from
> cancelling a domain registration.

> **COST CONTROL:** Stopping EC2 does not delete its EBS volume, and it does not
> delete the ALB. Delete the disposable resources promptly to avoid unnecessary
> charges.

### Cleanup verification

| Resource | Expected final state |
|---|---|
| Application Load Balancer | Deleted |
| Target group | Deleted |
| EC2 instance | Terminated |
| Lab EBS volume | Deleted |
| Lab security groups | Deleted |
| Lab ACM certificate | Deleted or intentionally retained |
| Lab DNS records | Deleted or intentionally retained |
| Purchased domain | Retained unless you choose to cancel it |

---

## 20. Key Takeaways

```text
Domain and public DNS
          |
          v
ACM validation CNAME
          |
          v
ACM Certificate: Issued
          |
          v
HTTPS :443 Listener
          |
          v
Application Load Balancer
          |
          v
HTTP :80 Target Group
          |
          v
EC2 Apache Web Server
```

- ACM provisions and manages certificates; it is not the web server.
- The domain registrar, DNS provider, ACM, and ALB can be different services.
- DNS validation proves control of the requested hostname.
- The ACM certificate and ALB must be in the same Region for this architecture.
- The certificate is attached to the ALB, where TLS terminates.
- The EC2 target can use HTTP for this simplified lab architecture.
- The EC2 security group should trust the ALB security group, not the internet.
- The application DNS record points users toward the ALB.
- Port `443` requires both security-group access and an HTTPS listener.
- The port `80` listener should redirect users to HTTPS after testing is complete.
- The validation CNAME should remain for ACM managed renewal.
- Effective troubleshooting follows evidence from DNS to ALB to target health.

---

## Reference Documentation

### AWS

- [What is AWS Certificate Manager?](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)
- [Request a public ACM certificate](https://docs.aws.amazon.com/acm/latest/userguide/acm-public-certificates.html)
- [ACM domain ownership validation](https://docs.aws.amazon.com/acm/latest/userguide/domain-ownership-validation.html)
- [Troubleshoot ACM DNS validation](https://docs.aws.amazon.com/acm/latest/userguide/troubleshooting-DNS-validation.html)
- [DNS-validated certificate renewal](https://docs.aws.amazon.com/acm/latest/userguide/dns-renewal-validation.html)
- [Create an Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-application-load-balancer.html)
- [ALB security groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html)
- [Create an HTTPS listener](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)
- [ALB redirect actions](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/rule-action-types.html#redirect-actions)
- [Route 53 alias and non-alias records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html)
- [Troubleshoot Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)

### Domain options

- [GitHub Student Developer Pack](https://education.github.com/pack/)
- [GitHub Student Developer Pack terms](https://docs.github.com/en/education/about-github-education/github-education-for-students/github-terms-and-conditions-for-the-student-developer-pack)
- [FreeDNS / afraid.org](https://freedns.afraid.org/)
- [FreeDNS DNS record types](https://freedns.afraid.org/faq/type.php)

---

*AWS re/Start Batch 29 and 30 — ACM, Application Load Balancer, and HTTPS Lab*
