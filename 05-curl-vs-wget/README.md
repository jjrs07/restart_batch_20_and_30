# Downloading Files with `curl` and `wget`

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 20–30 minutes<br>
**Format:** Follow along in a Linux terminal (WSL, EC2, or a lab machine).

---

## Learning Objectives

By the end of this lab, you will be able to:

1. Explain the main differences between `curl` and `wget`
2. Download and name a file with either command
3. Verify that a download succeeded
4. Choose the more appropriate tool for a particular task

---

## Before You Start

Check whether the commands are installed:

```bash
curl --version
wget --version
unzip -v
```

On Ubuntu or Debian, install any missing commands with:

```bash
sudo apt update
sudo apt install -y curl wget unzip
```

> The examples download the 64-bit x86 AWS CLI package. On an ARM-based machine,
> use `https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip` instead.

---

## `curl` vs `wget` at a Glance

Both commands can download files over HTTP and HTTPS, but they have different strengths.

| Feature | `curl` | `wget` |
|---|---|---|
| Main purpose | Transfer data to or from a server | Download files and websites |
| Default output | Writes the response to the terminal | Saves the response as a file |
| Choose output name | `-o filename` (lowercase) | `-O filename` (uppercase) |
| Follow HTTP redirects | Add `-L` | Follows redirects automatically |
| API requests | Excellent: supports headers, request methods, authentication, and request bodies | Not its main strength |
| Recursive website download | Not supported | Supported with options such as `--recursive` |
| Resume a partial download | `-C -` | `-c` or `--continue` |
| Protocol support | Supports many network protocols | Focused mainly on web and file downloads |

> **Easy mistake:** `curl` uses lowercase `-o`, while `wget` uses uppercase `-O`
> to choose the output filename. Options in Linux are case-sensitive.

---

## Demo 1 — Download a File with `curl`

Create a separate working directory so this demo does not conflict with the `wget` demo:

```bash
mkdir -p /tmp/curl-demo
cd /tmp/curl-demo
```

Download the AWS CLI ZIP file:

```bash
curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

Here, `-L` follows redirects and `-o` saves the response as `awscliv2.zip` instead
of printing binary data in the terminal.

Confirm that the file exists and is a valid ZIP archive:

```bash
ls -lh awscliv2.zip
unzip -t awscliv2.zip
```

Extract it:

```bash
unzip awscliv2.zip
```

If you intend to install the AWS CLI on this machine, run:

```bash
sudo ./aws/install
aws --version
```

> Installing is optional. Only run an installer downloaded from a source you trust.

---

## Demo 2 — Download the Same File with `wget`

Use another directory so you can demonstrate both tools independently:

```bash
mkdir -p /tmp/wget-demo
cd /tmp/wget-demo
```

Download the same AWS CLI ZIP file:

```bash
wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip"
```

Confirm and test the download:

```bash
ls -lh awscliv2.zip
unzip -t awscliv2.zip
```

Extract it:

```bash
unzip awscliv2.zip
```

If you did not already install the AWS CLI during the `curl` demo and want to install it:

```bash
sudo ./aws/install
aws --version
```

**What this proves:** the resulting file has the same name and contents regardless
of which tool downloaded it. The difference is how each command is designed to be used.

---

## When `curl` Is More Appropriate

### Use case: calling a REST API

APIs commonly require a request method, headers, authentication, or a JSON body.
`curl` is designed for this kind of data transfer.

For example, retrieve information from a public API and fail clearly on an HTTP error:

```bash
curl --fail --silent --show-error \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/curl/curl"
```

`curl` is the better choice here because it can easily:

- Send GET, POST, PUT, PATCH, and DELETE requests
- Add request headers with `-H`
- Send form or JSON data
- Use authentication tokens
- Return response data to the terminal or pipe it to another command

**Rule of thumb:** use `curl` when the response is **data you want to inspect or
process**, especially when working with an API.

---

## When `wget` Is More Appropriate

### Use case: a long file download that may be interrupted

Suppose a large download stops because the network connection drops. `wget` has a
simple continue option:

```bash
wget -c "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip"
```

Run the same command again after an interruption and `wget -c` attempts to continue
from the partial file rather than starting over. `wget` is also useful for downloading
multiple linked resources or mirroring website content when you have permission to do so.

**Rule of thumb:** use `wget` when the response is primarily a **file you want to
save**, especially for unattended, recursive, or resumable downloads.

> `curl` can also resume downloads with `curl -C - -o filename URL`. These are
> strengths, not hard limitations: choose the interface that best fits the task.

---

## Quick Practice

1. Which option chooses the output filename in `curl`?
2. Which option chooses the output filename in `wget`?
3. Why is `-L` commonly used with `curl` download commands?
4. Which tool would you choose to send JSON to an API, and why?
5. Which tool would you choose to mirror permitted documentation for offline use, and why?
6. How would you resume an interrupted download with each tool?

---

## Clean Up

The demo files are temporary and can be removed after the lab:

```bash
rm -rf /tmp/curl-demo /tmp/wget-demo
```

This removes only the two demo directories. It does not uninstall the AWS CLI.

---

## Quick Reference

```bash
# Download and choose a filename with curl
curl -L "URL" -o "filename"

# Download and choose a filename with wget
wget "URL" -O "filename"

# Resume an interrupted download
curl -C - -o "filename" "URL"
wget -c "URL" -O "filename"
```

---

*AWS re/Start Batch 29 and 30 — Downloading Files with `curl` and `wget`*
