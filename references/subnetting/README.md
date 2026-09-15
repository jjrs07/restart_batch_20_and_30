# IPv4 Subnetting Cheat Sheet

Quick reference for IPv4 CIDR prefixes, subnet masks, address counts, and example address ranges.

[View the rendered HTML version](https://jjrs07.github.io/restart_batch_20_and_30/references/subnetting/)

## How to read the table

- **Prefix bits** identify the network portion of the address.
- **Host bits** are calculated as `32 - prefix bits`.
- **Total addresses** are calculated as `2 ^ host bits` and include network and broadcast addresses where applicable.
- **Sample range** shows the complete block containing the example address `198.168.0.0`. It is an illustration, not a reserved documentation range.

> [!NOTE]
> Traditional subnets usually reserve the first address as the network address and the last as the broadcast address. `/31` is commonly used for point-to-point links, while `/32` identifies a single host.

## CIDR reference

Rows marked **AWS VPC ✓** are valid IPv4 CIDR sizes for both VPCs and subnets:
`/16` through `/28`. AWS reserves the first four and last IPv4 address in every
subnet. See [AWS subnet CIDR sizing](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html).

| CIDR | Host bits | Total addresses | Subnet mask | Binary subnet mask | Sample range |
|---:|---:|---:|---|---|---|
| `/32` | 0 | 1 | `255.255.255.255` | `11111111.11111111.11111111.11111111` | `198.168.0.0` |
| `/31` | 1 | 2 | `255.255.255.254` | `11111111.11111111.11111111.11111110` | `198.168.0.0` – `198.168.0.1` |
| `/30` | 2 | 4 | `255.255.255.252` | `11111111.11111111.11111111.11111100` | `198.168.0.0` – `198.168.0.3` |
| `/29` | 3 | 8 | `255.255.255.248` | `11111111.11111111.11111111.11111000` | `198.168.0.0` – `198.168.0.7` |
| **`/28` AWS VPC ✓** | 4 | 16 | `255.255.255.240` | `11111111.11111111.11111111.11110000` | `198.168.0.0` – `198.168.0.15` |
| **`/27` AWS VPC ✓** | 5 | 32 | `255.255.255.224` | `11111111.11111111.11111111.11100000` | `198.168.0.0` – `198.168.0.31` |
| **`/26` AWS VPC ✓** | 6 | 64 | `255.255.255.192` | `11111111.11111111.11111111.11000000` | `198.168.0.0` – `198.168.0.63` |
| **`/25` AWS VPC ✓** | 7 | 128 | `255.255.255.128` | `11111111.11111111.11111111.10000000` | `198.168.0.0` – `198.168.0.127` |
| **`/24` AWS VPC ✓** | 8 | 256 | `255.255.255.0` | `11111111.11111111.11111111.00000000` | `198.168.0.0` – `198.168.0.255` |
| **`/23` AWS VPC ✓** | 9 | 512 | `255.255.254.0` | `11111111.11111111.11111110.00000000` | `198.168.0.0` – `198.168.1.255` |
| **`/22` AWS VPC ✓** | 10 | 1,024 | `255.255.252.0` | `11111111.11111111.11111100.00000000` | `198.168.0.0` – `198.168.3.255` |
| **`/21` AWS VPC ✓** | 11 | 2,048 | `255.255.248.0` | `11111111.11111111.11111000.00000000` | `198.168.0.0` – `198.168.7.255` |
| **`/20` AWS VPC ✓** | 12 | 4,096 | `255.255.240.0` | `11111111.11111111.11110000.00000000` | `198.168.0.0` – `198.168.15.255` |
| **`/19` AWS VPC ✓** | 13 | 8,192 | `255.255.224.0` | `11111111.11111111.11100000.00000000` | `198.168.0.0` – `198.168.31.255` |
| **`/18` AWS VPC ✓** | 14 | 16,384 | `255.255.192.0` | `11111111.11111111.11000000.00000000` | `198.168.0.0` – `198.168.63.255` |
| **`/17` AWS VPC ✓** | 15 | 32,768 | `255.255.128.0` | `11111111.11111111.10000000.00000000` | `198.168.0.0` – `198.168.127.255` |
| **`/16` AWS VPC ✓** | 16 | 65,536 | `255.255.0.0` | `11111111.11111111.00000000.00000000` | `198.168.0.0` – `198.168.255.255` |
| `/15` | 17 | 131,072 | `255.254.0.0` | `11111111.11111110.00000000.00000000` | `198.168.0.0` – `198.169.255.255` |
| `/14` | 18 | 262,144 | `255.252.0.0` | `11111111.11111100.00000000.00000000` | `198.168.0.0` – `198.171.255.255` |
| `/13` | 19 | 524,288 | `255.248.0.0` | `11111111.11111000.00000000.00000000` | `198.168.0.0` – `198.175.255.255` |
| `/12` | 20 | 1,048,576 | `255.240.0.0` | `11111111.11110000.00000000.00000000` | `198.160.0.0` – `198.175.255.255` |
| `/11` | 21 | 2,097,152 | `255.224.0.0` | `11111111.11100000.00000000.00000000` | `198.160.0.0` – `198.191.255.255` |
| `/10` | 22 | 4,194,304 | `255.192.0.0` | `11111111.11000000.00000000.00000000` | `198.128.0.0` – `198.191.255.255` |
| `/9` | 23 | 8,388,608 | `255.128.0.0` | `11111111.10000000.00000000.00000000` | `198.128.0.0` – `198.255.255.255` |
| `/8` | 24 | 16,777,216 | `255.0.0.0` | `11111111.00000000.00000000.00000000` | `198.0.0.0` – `198.255.255.255` |
| `/7` | 25 | 33,554,432 | `254.0.0.0` | `11111110.00000000.00000000.00000000` | `198.0.0.0` – `199.255.255.255` |
| `/6` | 26 | 67,108,864 | `252.0.0.0` | `11111100.00000000.00000000.00000000` | `196.0.0.0` – `199.255.255.255` |
| `/5` | 27 | 134,217,728 | `248.0.0.0` | `11111000.00000000.00000000.00000000` | `192.0.0.0` – `199.255.255.255` |
| `/4` | 28 | 268,435,456 | `240.0.0.0` | `11110000.00000000.00000000.00000000` | `192.0.0.0` – `207.255.255.255` |
| `/3` | 29 | 536,870,912 | `224.0.0.0` | `11100000.00000000.00000000.00000000` | `192.0.0.0` – `223.255.255.255` |
| `/2` | 30 | 1,073,741,824 | `192.0.0.0` | `11000000.00000000.00000000.00000000` | `192.0.0.0` – `255.255.255.255` |
| `/1` | 31 | 2,147,483,648 | `128.0.0.0` | `10000000.00000000.00000000.00000000` | `128.0.0.0` – `255.255.255.255` |
| `/0` | 32 | 4,294,967,296 | `0.0.0.0` | `00000000.00000000.00000000.00000000` | `0.0.0.0` – `255.255.255.255` |

## Additional tool

[CIDR to IPv4 Address Range Utility](https://www.ipaddressguide.com/cidr)

## Practice exercises: Client subnet requirements

For each scenario, use **Variable Length Subnet Masking (VLSM)** and allocate the
largest subnet first. Choose the smallest subnet that meets each requirement.

> [!IMPORTANT]
> In an AWS VPC subnet, AWS reserves five IP addresses. For these exercises,
> calculate usable hosts as `total addresses - 5`.

For every subnet, identify:

1. Subnet name and type (public or private)
2. Network address and CIDR prefix
3. Subnet mask
4. Full address range
5. Number of usable AWS host addresses

### Associate the subnet plan with an AWS VPC

After solving a scenario on paper, build it in the **Amazon VPC console**. Use
the VPC CIDR and subnet CIDRs from that scenario.

1. Open **VPC** → **Your VPCs** and create a VPC using the scenario's VPC CIDR.
   Use a name such as `scenario-1-vpc`.
2. Open **Subnets** and create every required subnet inside that VPC. Give each
   subnet a descriptive name, such as `scenario-1-public`, `scenario-1-hr`, and
   `scenario-1-sales`.
3. Choose an Availability Zone for each subnet. A subnet exists entirely within
   one Availability Zone.
4. Create and attach an **internet gateway** to the VPC.
5. Create a route table named `public-rt`, add the route below, and explicitly
   associate only the public subnet or subnets with it.

   | Destination | Target |
   |---|---|
   | `0.0.0.0/0` | The attached internet gateway |

6. Create a route table named `private-rt` and explicitly associate all private
   subnets with it. For this exercise, leave only the automatically created
   `local` route; do not add a route to the internet gateway.
7. For each public subnet, enable **auto-assign public IPv4 address** if EC2
   instances launched there need public IPv4 addresses.
8. Open each route table's **Subnet associations** tab and verify that every
   subnet is associated with the intended route table.

> [!NOTE]
> A subnet is public because its route table has a direct route to an internet
> gateway—not because its name contains the word `public`. A private subnet can
> use a NAT gateway for outbound internet access, but NAT gateways incur charges
> and are not required for this subnetting exercise.

#### AWS verification checklist

- The VPC CIDR matches the selected scenario.
- Every subnet CIDR is inside the VPC CIDR and no subnet CIDRs overlap.
- Public subnets are associated with `public-rt`.
- Private subnets are associated with `private-rt`.
- Only `public-rt` has the `0.0.0.0/0` route to the internet gateway.
- The internet gateway is attached to the correct VPC.

> [!WARNING]
> Delete the practice VPC resources after the exercise. If you add EC2 instances
> or a NAT gateway, they can generate AWS charges.

AWS references: [Create a VPC](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html),
[Create subnets](https://docs.aws.amazon.com/vpc/latest/userguide/create-subnets.html),
and [Configure route-table associations](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-route-tables.html).

### Scenario 1: Small consulting company

A consulting company is moving its first application to AWS. The client has
been assigned the VPC CIDR block `10.10.0.0/23` and needs:

- One **public subnet** for web servers and load balancers: **100 hosts**
- One **private HR subnet**: **100 hosts**
- One **private Sales subnet**: **100 hosts**

Design three non-overlapping subnets inside the assigned VPC block.

### Scenario 2: Online retail company

An online retailer has been assigned the VPC CIDR block `10.20.0.0/22`. The
client needs:

- One **public web subnet**: **200 hosts**
- One **private application subnet**: **120 hosts**
- One **private database subnet**: **50 hosts**
- One **private management subnet**: **20 hosts**

Design four non-overlapping subnets and state how much address space remains
unallocated.

### Scenario 3: Regional office network

A company is building an AWS network for a regional office. The assigned VPC
CIDR block is `172.16.0.0/22`. The client needs:

- One **private Operations subnet**: **300 hosts**
- One **private Finance subnet**: **120 hosts**
- One **private HR subnet**: **60 hosts**
- One **public services subnet**: **25 hosts**
- One **private monitoring subnet**: **10 hosts**

Design five non-overlapping subnets. Allocate them from the beginning of the
VPC address range, largest to smallest.

<details>
<summary><strong>Answer key</strong></summary>

### Scenario 1 solution

Each requirement needs a `/25`, which provides 128 total addresses and 123
usable AWS host addresses.

| Subnet | Network/CIDR | Subnet mask | Full range | Usable AWS hosts |
|---|---|---|---|---:|
| Public | `10.10.0.0/25` | `255.255.255.128` | `10.10.0.0` – `10.10.0.127` | 123 |
| HR | `10.10.0.128/25` | `255.255.255.128` | `10.10.0.128` – `10.10.0.255` | 123 |
| Sales | `10.10.1.0/25` | `255.255.255.128` | `10.10.1.0` – `10.10.1.127` | 123 |

The unused range is `10.10.1.128` – `10.10.1.255`.

### Scenario 2 solution

| Subnet | Network/CIDR | Subnet mask | Full range | Usable AWS hosts |
|---|---|---|---|---:|
| Public web | `10.20.0.0/24` | `255.255.255.0` | `10.20.0.0` – `10.20.0.255` | 251 |
| Application | `10.20.1.0/25` | `255.255.255.128` | `10.20.1.0` – `10.20.1.127` | 123 |
| Database | `10.20.1.128/26` | `255.255.255.192` | `10.20.1.128` – `10.20.1.191` | 59 |
| Management | `10.20.1.192/27` | `255.255.255.224` | `10.20.1.192` – `10.20.1.223` | 27 |

The unallocated ranges are `10.20.1.224` – `10.20.1.255` and
`10.20.2.0` – `10.20.3.255`, for a total of 544 addresses.

### Scenario 3 solution

| Subnet | Network/CIDR | Subnet mask | Full range | Usable AWS hosts |
|---|---|---|---|---:|
| Operations | `172.16.0.0/23` | `255.255.254.0` | `172.16.0.0` – `172.16.1.255` | 507 |
| Finance | `172.16.2.0/25` | `255.255.255.128` | `172.16.2.0` – `172.16.2.127` | 123 |
| HR | `172.16.2.128/25` | `255.255.255.128` | `172.16.2.128` – `172.16.2.255` | 123 |
| Public services | `172.16.3.0/27` | `255.255.255.224` | `172.16.3.0` – `172.16.3.31` | 27 |
| Monitoring | `172.16.3.32/28` | `255.255.255.240` | `172.16.3.32` – `172.16.3.47` | 11 |

The unused range is `172.16.3.48` – `172.16.3.255`.

</details>

---

Created by James Joseph Santos.
