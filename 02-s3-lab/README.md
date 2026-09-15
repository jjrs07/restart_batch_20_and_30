# Amazon S3 Hands-On Walkthrough (AWS Management Console)

**AWS re/Start — Batch 29 and 30**
**Duration:** 45–60 minutes
**Format:** Follow along with your instructor. Do every step in your own sandbox account.

---

## Before You Start

| Item | Value |
|---|---|
| Region | `us-east-1` (N. Virginia) — **use the same Region as your instructor the whole time** |
| Your initials | e.g. `jdc` — you will use this in your bucket name |
| Today's date | e.g. `20260806` |

**Your bucket name for this lab:**

```
restart-b29-<yourinitials>-<yyyymmdd>
```

Example: `restart-b29-jdc-20260806`

> **Why the weird name?** S3 bucket names are **globally unique across every AWS account on the planet**. Not per account. Not per Region. Global. If someone in Brazil already took `mybucket`, you can never have it. That is why we add initials and a date.

---

## Learning Objectives

By the end of this walkthrough you will be able to:

1. Explain S3 bucket naming rules and why they exist
2. Create a bucket with secure defaults
3. Upload, download, and inspect objects
4. Explain the difference between a bucket, an object, a key, and a prefix
5. Turn on and demonstrate **Versioning**
6. Configure **encryption at rest** (SSE-S3 and SSE-KMS) and explain the difference
7. Explain **Block Public Access**, bucket policies, and IAM policies, and when to use each
8. Generate a **presigned URL** for temporary access
9. Apply a **Lifecycle rule** to control storage cost
10. Clean up every resource so you are not billed

---

## Part 0 — The Vocabulary (2 min)

| Term | What it actually is |
|---|---|
| **Bucket** | The container. Lives in one Region. Globally unique name. |
| **Object** | The file plus its metadata. Max 5 TB per object. |
| **Key** | The full name of the object inside the bucket, e.g. `reports/2026/q1.csv` |
| **Prefix** | The part before the last `/`. S3 has **no real folders** — the "folders" you see in the console are just prefixes in the key name. |
| **ARN** | The globally unique ID of the resource, e.g. `arn:aws:s3:::my-bucket/*` |

> **Remember this:** S3 is **object storage**, not a file system. You cannot mount it as a drive and you cannot edit part of a file in place. You replace the whole object.

---

## Part 1 — Bucket Naming Rules (3 min)

Before you click anything, know the rules. You will hit these on the exam and in real projects.

**Must:**
- 3 to 63 characters
- Lowercase letters, numbers, hyphens `-`, and dots `.` only
- Start and end with a letter or number
- Be globally unique

**Must NOT:**
- Contain uppercase letters or underscores `_`
- Be formatted like an IP address (`192.168.1.1`)
- Start with `xn--`, `sthree-`, or `amzn-s3-demo-`
- End with `-s3alias` or `--ol-s3`

**Strongly avoid:**
- **Dots in the name.** A bucket named `my.data.bucket` breaks HTTPS virtual-hosted-style access because the wildcard TLS certificate `*.s3.amazonaws.com` does not match multi-level names. Use hyphens.

**Good practice naming pattern used in industry:**

```
<company>-<env>-<workload>-<region>-<account-suffix>
cvt-prod-invoices-use1-4471
```

This tells you at a glance who owns it, which environment it belongs to, what it holds, and where it lives.

---

## Part 2 — Create the Bucket (5 min)

1. Sign in to the **AWS Management Console**.
2. Top right — confirm your **Region** says **N. Virginia (us-east-1)**.
3. In the search bar type **S3** and open the S3 console.
4. Click **Create bucket**.

Fill in the form:

| Field | What to choose | Why |
|---|---|---|
| **Bucket type** | General purpose | Directory buckets are for S3 Express One Zone (very low latency, single AZ). Not needed here. |
| **Bucket name** | `restart-b29-<initials>-<date>` | Global uniqueness |
| **Region** | US East (N. Virginia) us-east-1 | Data residency and latency |
| **Copy settings from existing bucket** | Skip | |
| **Object Ownership** | **ACLs disabled (recommended)** — leave as is | ACLs are legacy. Modern access control is IAM + bucket policy. |
| **Block Public Access** | **Leave ALL FOUR boxes checked** | This is your safety net |
| **Bucket Versioning** | **Disable** for now | We will turn it on later so you can see the before/after |
| **Default encryption** | **SSE-S3 (SSE-S3)** — this is already the default | Every object gets encrypted at rest automatically |
| **Bucket Key** | Enabled | Only matters for KMS. Reduces KMS API calls and cost. |

5. Click **Create bucket**.

**Checkpoint:** You should see your bucket in the list with **Access: Bucket and objects not public**.

> **Common mistake:** Students pick a name that is already taken and get `BucketAlreadyExists`. That error means someone else in the world owns it. `BucketAlreadyOwnedByYou` means *you* already made it. Two different errors, two different meanings.

---

## Part 3 — Upload Objects and Understand Keys (6 min)

1. Click your bucket name to open it.
2. Click **Upload** → **Add files**.
3. Create a small text file on your laptop first. Name it `hello.txt` and put this inside:

```
Hello from AWS re/Start Batch 29 and 30 - version 1
```

4. Upload it. Leave all the defaults. Click **Upload**. Click **Close**.

Now create a prefix:

5. Click **Create folder**. Name it `logs`. Click **Create folder**.
6. Open `logs` and upload the same `hello.txt` there.

7. Click on the object and look at the **Object URL** and the **Key**.

You should see:

```
Key:  logs/hello.txt
URL:  https://restart-b29-jdc-20260806.s3.us-east-1.amazonaws.com/logs/hello.txt
```

8. **Copy the Object URL and paste it into a new browser tab.**

You will get:

```xml
<Error><Code>AccessDenied</Code>...
```

**This is correct and expected.** The object exists, but you are anonymous in that tab. No credentials, no access. This proves S3 is private by default.

> **Teaching point:** "It works in the console but not in the browser" is not a bug. The console signs your requests with your IAM identity. A raw browser tab does not.

---

## Part 4 — Versioning (8 min)

Versioning protects you from accidental overwrite and accidental delete. This is the single most common "please help, I deleted prod data" prevention control.

### Turn it on

1. In your bucket, go to the **Properties** tab.
2. Find **Bucket Versioning** → **Edit** → select **Enable** → **Save changes**.

### Prove it works

3. Edit `hello.txt` on your laptop. Change the text to:

```
Hello from AWS re/Start Batch 29 and 30 - version 2
```

4. Upload it again to the **root** of the bucket (same key, `hello.txt`).
5. Go to the **Objects** tab and toggle **Show versions** to ON.

You now see **two versions** of `hello.txt`, each with its own **Version ID**. The newest one is the *current* version. The old one is still there and still billable.

6. Click the older version → **Download**. Confirm it says "version 1".

### Prove delete protection

7. Toggle **Show versions** OFF.
8. Select `hello.txt` → **Delete** → type `permanently delete` → **Delete objects**.
9. The object disappears from the list.
10. Toggle **Show versions** back ON.

Your object is still there. Plus a new zero-byte entry with a **Delete marker** badge.

> **What just happened:** In a versioned bucket, a normal delete does not delete anything. It writes a **delete marker** on top. The data is intact underneath.

### Restore it

11. With **Show versions** ON, select the row with the **Delete marker**.
12. Click **Delete** → type `permanently delete` → confirm.
13. Toggle **Show versions** OFF. Your object is back.

> **Important cost lesson:** Versioning is not free. Every version is a stored object you pay for. A bucket with versioning on and no lifecycle rule will grow forever. We fix that in Part 8.

**Also note:** Once you enable versioning you can never fully turn it off. You can only **suspend** it. Existing versions stay.

---

## Part 5 — Encryption at Rest (7 min)

**Every object in S3 is encrypted at rest by default.** Since January 2023 you cannot turn it off. The question is not *if*, it is *which key manages it*.

| Option | Who manages the key | Cost | Audit trail | Use when |
|---|---|---|---|---|
| **SSE-S3** (AES-256) | AWS, fully | Free | No per-object key usage log | Default. Fine for most workloads. |
| **SSE-KMS** | AWS KMS, you control the policy | KMS key + API request charges | Yes — every decrypt shows in CloudTrail | Regulated data, need key rotation control, need to deny access at the key level |
| **DSSE-KMS** | Double layer KMS | Highest | Yes | Rare. Certain government/defence requirements. |
| **SSE-C** | **You** supply the key on every request | Free | You own key loss risk | Almost never. If you lose the key, the data is gone. |

### Check your current setting

1. **Properties** tab → scroll to **Default encryption**.
2. It should say **Server-side encryption with Amazon S3 managed keys (SSE-S3)**.

### Switch to SSE-KMS

3. Click **Edit** on Default encryption.
4. Select **Server-side encryption with AWS Key Management Service keys (SSE-KMS)**.
5. Choose **AWS managed key (aws/s3)**.
6. **Bucket Key: Enable** — leave this on.
7. **Save changes**.

8. Upload `hello.txt` one more time.
9. Click the object → **Properties** → scroll to **Server-side encryption settings**. It now shows **AWS-KMS** and the key ARN.

> **Why Bucket Key matters:** Without it, S3 calls KMS once per object operation. On a bucket with millions of objects that is a real bill and can hit KMS request throttling limits. S3 Bucket Keys cut those calls by up to 99%. Turn this on for any KMS-encrypted bucket.

> **Important:** Changing default encryption only affects **new** objects. Objects you uploaded before are still SSE-S3. To re-encrypt old objects you copy them over themselves or use S3 Batch Operations.

### Encryption in transit

Encryption at rest is only half the story. Data moving to and from S3 should be forced onto HTTPS. We do that with a bucket policy in the next section.

---

## Part 6 — Access Control: The Three Layers (10 min)

This is the part people get wrong in real jobs. Learn the mental model.

```
         Block Public Access   <-- account/bucket-level guardrail, wins over everything
                  |
         Bucket Policy         <-- resource-based, attached TO the bucket, can grant cross-account
                  |
         IAM Policy            <-- identity-based, attached to a user/group/role
                  |
              (ACLs)           <-- legacy, disabled by default, do not use
```

**Rule of thumb:**
- Controlling **who in my account** can do what → **IAM policy**
- Controlling **what can be done to this bucket**, including from other accounts or anonymous → **bucket policy**
- Making absolutely sure nothing is ever public by accident → **Block Public Access**

An explicit **Deny** anywhere always beats an **Allow** anywhere.

### 6a. Look at Block Public Access

1. **Permissions** tab → **Block public access (bucket settings)**.
2. All four should say **On**:
   - Block public access to buckets and objects granted through *new* ACLs
   - Block public access to buckets and objects granted through *any* ACLs
   - Block public access to buckets and objects granted through *new* public bucket or access point policies
   - Block public access to buckets and objects granted through *any* public bucket or access point policies

> **Do not turn these off in this lab.** In the real world you turn them off only for a deliberate public static website, and even then the modern pattern is CloudFront + Origin Access Control with the bucket kept fully private.

### 6b. Add a bucket policy that forces HTTPS

This is a policy every production bucket should have.

1. **Permissions** tab → **Bucket policy** → **Edit**.
2. Paste this. **Replace the bucket name with yours.**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::restart-b29-jdc-20260806",
        "arn:aws:s3:::restart-b29-jdc-20260806/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

3. **Save changes**.

**Read the policy out loud with your instructor:**
- `Effect: Deny` — this blocks
- `Principal: "*"` — applies to everyone, including you
- `Action: s3:*` — every S3 action
- `Resource` — **two ARNs**. One without `/*` for bucket-level actions like `ListBucket`. One with `/*` for object-level actions like `GetObject`. Getting this wrong is the #1 bucket policy bug.
- `Condition` — only when the request did **not** use TLS

> **Common mistake:** Writing only `arn:aws:s3:::my-bucket/*` and then wondering why `ListBucket` still works. Bucket-level and object-level actions need different ARNs.

### 6c. See what a public policy looks like (read only, do not apply)

If Block Public Access were off and you wanted a public read bucket, the policy would be:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::YOUR-BUCKET/*"
  }]
}
```

The console will refuse to save this while Block Public Access is on, and it will warn you in red if you disable it. **That red banner exists because public S3 buckets are one of the most common causes of real-world data breaches.** Respect it.

### 6d. IAM Access Analyzer

1. **Permissions** tab → scroll to the bottom → **Access Analyzer for S3** (or open IAM → Access Analyzer).
2. This tool tells you which buckets are shared publicly or cross-account. In a real job you check this weekly.

---

## Part 7 — Presigned URLs (5 min)

You need to give someone a file for 15 minutes without giving them an AWS account and without making the bucket public. That is a **presigned URL**.

1. Go to **Objects**, click `hello.txt`.
2. Click **Object actions** → **Share with a presigned URL**.
3. Set the time to **5 minutes**.
4. Click **Create presigned URL**. It is copied to your clipboard.
5. Paste it into a browser tab. **The file downloads.**

Look at the URL. You will see query parameters like `X-Amz-Signature`, `X-Amz-Expires`, `X-Amz-Credential`. Those carry the signed proof of your identity.

> **Key concept:** The presigned URL inherits **your** permissions. You are lending your access, not the bucket's. If your IAM role loses `s3:GetObject`, the link stops working even before it expires.

> **Security note:** Anyone who gets the link can use it until it expires. Treat presigned URLs like temporary passwords. Keep expiry short.

---

## Part 8 — Storage Classes and Lifecycle (6 min)

### Storage classes, short version

| Class | Best for | Retrieval | Min duration |
|---|---|---|---|
| **S3 Standard** | Hot, frequently accessed | Instant | None |
| **S3 Intelligent-Tiering** | Unknown or changing access patterns | Instant | None |
| **S3 Standard-IA** | Infrequent but needs instant access | Instant | 30 days |
| **S3 One Zone-IA** | Reproducible data, single AZ OK | Instant | 30 days |
| **S3 Glacier Instant Retrieval** | Archive, still needs milliseconds | Instant | 90 days |
| **S3 Glacier Flexible Retrieval** | Archive, minutes to hours OK | 1 min – 12 hr | 90 days |
| **S3 Glacier Deep Archive** | Cold archive, cheapest | 12–48 hr | 180 days |

> **Trap:** IA and Glacier classes have **minimum storage durations** and **per-GB retrieval fees**. Moving a 1 KB object to Glacier can cost you *more* than leaving it in Standard, because you also pay per-object overhead. Lifecycle transitions make sense for larger objects and real volume, not for 12 tiny text files.
>
> **When in doubt, use S3 Intelligent-Tiering.** It moves objects for you based on real access patterns, with no retrieval fees.

### Create a lifecycle rule

1. **Management** tab → **Lifecycle rules** → **Create lifecycle rule**.
2. **Rule name:** `restart-cleanup-rule`
3. **Rule scope:** Apply to **all objects in the bucket**. Tick the acknowledgement box.
4. Under **Lifecycle rule actions**, tick these three:
   - ☑ Transition noncurrent versions of objects between storage classes
   - ☑ Permanently delete noncurrent versions of objects
   - ☑ Delete expired object delete markers or incomplete multipart uploads
5. Configure:
   - Transition noncurrent versions to **Glacier Flexible Retrieval** after **30** days
   - Permanently delete noncurrent versions after **90** days, keep **2** newer versions
   - ☑ Delete expired object delete markers
   - ☑ Delete incomplete multipart uploads after **7** days
6. **Create rule**.

> **The incomplete multipart upload setting is the one everybody forgets.** When a large upload fails halfway, the parts that already landed stay in your bucket, invisible in the normal object list, and you pay for them forever. Add this rule to every bucket you ever create. It is free money back.

---

## Part 9 — Other Features Worth Knowing (3 min, discussion)

You do not need to configure these today, but you should be able to say what they do.

| Feature | One-line summary |
|---|---|
| **Server access logging** | Writes detailed request logs to another bucket. Free storage cost only, but best-effort delivery. |
| **CloudTrail data events** | Logs S3 object-level API calls. More reliable and searchable than access logs. Costs extra. |
| **S3 Event Notifications** | Fires an SNS, SQS, Lambda, or EventBridge event when an object is created or deleted. The classic serverless trigger. |
| **Cross-Region Replication (CRR)** | Copies objects to a bucket in another Region. Needs versioning on **both** buckets. Used for DR and compliance. |
| **Same-Region Replication (SRR)** | Same but within a Region. Used for log aggregation and account separation. |
| **S3 Object Lock** | WORM. Write once, read many. Nobody, not even root, can delete during the retention period. Must be enabled **at bucket creation**. |
| **MFA Delete** | Requires an MFA token to permanently delete a version. Root user only, CLI only. |
| **S3 Transfer Acceleration** | Uploads route through the nearest CloudFront edge. Helps for long-distance large uploads. |
| **Requester Pays** | The downloader pays the transfer cost, not the bucket owner. Used for public datasets. |
| **Static website hosting** | Serves HTML directly from the bucket. Modern pattern is CloudFront + OAC in front of a private bucket instead. |
| **S3 Storage Lens** | Account-wide dashboard of usage and cost optimisation opportunities. |

**Durability and availability, for the exam:**
- S3 Standard is designed for **99.999999999% (11 nines) durability** and **99.99% availability**.
- Data is redundantly stored across a minimum of **3 Availability Zones** (except One Zone-IA).
- **Durability is not backup.** S3 will faithfully replicate your mistake across all three AZs. Versioning, replication, and Object Lock are what protect you from *you*.

---

## Part 10 — Clean Up (5 min)

**Do this. Every time. Leftover resources cost money and clutter the sandbox.**

1. Open your bucket → **Objects** tab.
2. Toggle **Show versions** **ON**. This is critical — a versioned bucket looks empty but is not.
3. Select **all** rows, including delete markers.
4. **Delete** → type `permanently delete` → **Delete objects**.
5. Repeat until the versions list is completely empty.
6. Go back to the S3 bucket list.
7. Select your bucket → **Delete** → type the bucket name → **Delete bucket**.

> **If you get `BucketNotEmpty`:** you missed some versions or delete markers. Go back, toggle **Show versions** on, and clear everything.
>
> **Faster alternative:** In the bucket list, select the bucket and use **Empty**, then **Delete**. The **Empty** action handles versions for you.

---

## Quick Reference Card

**Bucket naming:** 3–63 chars, lowercase, numbers, hyphens. Globally unique. No underscores, no uppercase, avoid dots.

**Private by default.** Block Public Access is on for new buckets at the account level.

**Encrypted by default.** SSE-S3 unless you choose KMS.

**Versioning** protects against overwrite and delete. Cannot be disabled once enabled, only suspended.

**Delete in a versioned bucket** = adds a delete marker, does not remove data.

**Bucket policy resource ARNs:** you almost always need both `arn:aws:s3:::bucket` and `arn:aws:s3:::bucket/*`.

**Explicit Deny always wins.**

**Every bucket should have:** Block Public Access on, default encryption, a DenyInsecureTransport policy, and a lifecycle rule that aborts incomplete multipart uploads.

---

## Self-Check Questions

1. Why can two AWS accounts not both own a bucket named `data`?
2. You deleted an object from a versioned bucket. Where did it go and how do you get it back?
3. Your app gets `AccessDenied` but your IAM policy clearly allows `s3:GetObject`. Name three things that could be blocking it.
4. When would you choose SSE-KMS over SSE-S3, and what does it cost you?
5. Your bucket has 40 TB and grows every month even though nothing new is uploaded. What are two likely causes?
6. What is the difference between a bucket policy and an IAM policy, and which one lets another AWS account read your objects?
7. You need to share one file with a vendor for 24 hours. What is the safest way?

---

*AWS re/Start Batch 29 and 30 — Amazon S3 Hands-On Walkthrough*
