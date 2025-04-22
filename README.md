# Single-Page Static Website on AWS S3 + CloudFront

This repository contains a **single HTML file** hosted on AWS S3 with CloudFront CDN.

## Live Demo
[https://dakb2nb0eypqm.cloudfront.net](https://dakb2nb0eypqm.cloudfront.net)

## One-Time Setup
1. **Create S3 bucket** and enable static hosting (see `setup-commands.txt`)
2. **Create CloudFront distribution** with:
   - Origin = `malak-website.s3.amazonaws.com`
   - Origin Access Control (OAC)
   - Default root object = `index.html`
3. **Update S3 bucket policy** to allow only CloudFront access

## Security
- S3 bucket is **private** (no public access)
- CloudFront enforces HTTPS

## Files
- `index.html`: The complete website (HTML + inline CSS)
- `setup-commands.txt`: AWS CLI commands for setup
