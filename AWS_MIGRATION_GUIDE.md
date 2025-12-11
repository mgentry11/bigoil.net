# AWS Migration Guide for bigoil.net

This guide covers migrating bigoil.net from GoDaddy to AWS S3 with CloudFront CDN.

## Architecture Overview

```
                    ┌─────────────────┐
                    │   CloudFront    │
                    │   Distribution  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    S3 Bucket    │
                    │  bigoil.net     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        index.html     styles.css     script.js
```

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI installed and configured
3. Access to GoDaddy DNS management

## Step 1: Create S3 Bucket

### Via AWS CLI:
```bash
# Create the bucket (use your region)
aws s3 mb s3://bigoil.net --region us-east-1

# Enable static website hosting
aws s3 website s3://bigoil.net \
    --index-document index.html \
    --error-document index.html
```

### Via AWS Console:
1. Go to S3 Console > Create Bucket
2. Bucket name: `bigoil.net`
3. Region: `us-east-1` (required for CloudFront with custom domain)
4. Uncheck "Block all public access"
5. Acknowledge the public access warning
6. Create bucket

## Step 2: Configure Bucket Policy

Create a bucket policy for public read access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::bigoil.net/*"
        }
    ]
}
```

### Apply via CLI:
```bash
aws s3api put-bucket-policy --bucket bigoil.net --policy file://bucket-policy.json
```

## Step 3: Upload Website Files

```bash
# Navigate to the website directory
cd /Users/markgentry/Sites/bigoil.net

# Sync all files to S3
aws s3 sync . s3://bigoil.net --exclude ".DS_Store" --exclude "*.md"

# Set correct content types
aws s3 cp s3://bigoil.net/index.html s3://bigoil.net/index.html \
    --content-type "text/html" \
    --metadata-directive REPLACE

aws s3 cp s3://bigoil.net/styles.css s3://bigoil.net/styles.css \
    --content-type "text/css" \
    --metadata-directive REPLACE

aws s3 cp s3://bigoil.net/script.js s3://bigoil.net/script.js \
    --content-type "application/javascript" \
    --metadata-directive REPLACE

aws s3 cp s3://bigoil.net/favicon.svg s3://bigoil.net/favicon.svg \
    --content-type "image/svg+xml" \
    --metadata-directive REPLACE
```

## Step 4: Request SSL Certificate (ACM)

1. Go to AWS Certificate Manager (ACM) in **us-east-1** region
2. Click "Request a certificate"
3. Select "Request a public certificate"
4. Add domain names:
   - `bigoil.net`
   - `www.bigoil.net`
5. Select DNS validation
6. Click "Request"
7. Note the CNAME records provided for validation

### Add DNS Validation Records to GoDaddy:
1. Log into GoDaddy > DNS Management for bigoil.net
2. Add CNAME records as provided by ACM
3. Wait for validation (can take up to 30 minutes)

## Step 5: Create CloudFront Distribution

### Via AWS CLI:
```bash
aws cloudfront create-distribution \
    --origin-domain-name bigoil.net.s3.amazonaws.com \
    --default-root-object index.html
```

### Via Console (Recommended for Custom Domain):
1. Go to CloudFront > Create Distribution
2. **Origin Settings:**
   - Origin domain: `bigoil.net.s3.amazonaws.com`
   - Origin path: (leave empty)
   - Name: `bigoil-s3-origin`
   - S3 bucket access: Don't use OAI (using bucket policy instead)

3. **Default Cache Behavior:**
   - Viewer protocol policy: Redirect HTTP to HTTPS
   - Allowed HTTP methods: GET, HEAD
   - Cache policy: CachingOptimized

4. **Settings:**
   - Price class: Use all edge locations (best performance)
   - Alternate domain names (CNAMEs):
     - `bigoil.net`
     - `www.bigoil.net`
   - Custom SSL certificate: Select the ACM certificate created earlier
   - Default root object: `index.html`
   - Standard logging: Enable (optional, for analytics)

5. Create distribution
6. Note the CloudFront domain name (e.g., `d1234567890.cloudfront.net`)

## Step 6: Configure DNS at GoDaddy

### Update DNS Records:

**For root domain (bigoil.net):**
```
Type: A
Name: @
Value: [CloudFront IP - use ALIAS if supported, otherwise CNAME flattening]
TTL: 600
```

**For www subdomain:**
```
Type: CNAME
Name: www
Value: d1234567890.cloudfront.net (your CloudFront distribution domain)
TTL: 600
```

### If GoDaddy doesn't support ALIAS records for root domain:
You have two options:

**Option A: Use Route 53 (Recommended)**
1. Create a hosted zone in Route 53 for bigoil.net
2. Create an ALIAS record pointing to CloudFront
3. Update GoDaddy nameservers to Route 53 nameservers

**Option B: Use a redirect**
1. Set up www.bigoil.net as the primary
2. Use GoDaddy's forwarding to redirect bigoil.net to www.bigoil.net

## Step 7: Verify Deployment

```bash
# Test S3 website endpoint
curl -I http://bigoil.net.s3-website-us-east-1.amazonaws.com

# Test CloudFront distribution
curl -I https://d1234567890.cloudfront.net

# Test custom domain (after DNS propagation)
curl -I https://bigoil.net
curl -I https://www.bigoil.net
```

## Step 8: Set Up CI/CD (Optional)

### Using GitHub Actions:

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to S3

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Sync to S3
        run: aws s3 sync . s3://bigoil.net --exclude ".git/*" --exclude ".github/*" --exclude "*.md"

      - name: Invalidate CloudFront Cache
        run: aws cloudfront create-invalidation --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} --paths "/*"
```

## Deployment Commands Summary

```bash
# Upload/update files
cd /Users/markgentry/Sites/bigoil.net
aws s3 sync . s3://bigoil.net --exclude ".DS_Store" --exclude "*.md"

# Invalidate CloudFront cache (after updates)
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"

# Check distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID --query "Distribution.Status"
```

## Cost Estimates (Monthly)

| Service | Estimated Cost |
|---------|---------------|
| S3 Storage | ~$0.01 (minimal for static site) |
| S3 Requests | ~$0.01-0.05 |
| CloudFront | ~$1-5 (depends on traffic) |
| Route 53 | $0.50 per hosted zone |
| ACM Certificate | Free |
| **Total** | **~$2-6/month** |

## Troubleshooting

### 403 Forbidden Error
- Check S3 bucket policy is correctly applied
- Verify "Block all public access" is disabled
- Ensure CloudFront origin is configured correctly

### SSL Certificate Not Working
- Verify certificate is in us-east-1 region
- Check certificate status is "Issued"
- Confirm CNAMEs are correctly set in GoDaddy

### DNS Not Resolving
- Wait for DNS propagation (up to 48 hours)
- Verify CNAME records are correct
- Use `dig` or `nslookup` to check DNS:
```bash
dig bigoil.net
nslookup bigoil.net
```

### CloudFront Showing Old Content
- Create an invalidation:
```bash
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

## Rollback Plan

If issues arise, you can temporarily point back to GoDaddy:
1. In GoDaddy DNS, update A record to point to GoDaddy hosting IP
2. Remove CNAME for www pointing to CloudFront
3. The site will be back on GoDaddy within DNS TTL period

## Security Best Practices

1. **Enable CloudFront logging** for traffic analysis
2. **Set up AWS WAF** if needed for additional security
3. **Use IAM roles** with minimal permissions for deployment
4. **Enable versioning** on S3 bucket for file recovery
5. **Set up CloudWatch alarms** for error monitoring

---

## Quick Reference

| Item | Value |
|------|-------|
| S3 Bucket | `bigoil.net` |
| S3 Website Endpoint | `bigoil.net.s3-website-us-east-1.amazonaws.com` |
| CloudFront Distribution | `d[YOUR_ID].cloudfront.net` |
| SSL Certificate ARN | `arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT_ID` |
| Primary Domain | `https://bigoil.net` |
| WWW Domain | `https://www.bigoil.net` |
