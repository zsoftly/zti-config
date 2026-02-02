# SAML Metadata Files

This directory is for storing SAML Service Provider (SP) metadata XML files.

## Usage

When configuring SAML providers in Authentik (like AWS SSO, Salesforce, etc.),
you may need to upload SP metadata files.

### Example: AWS SSO

1. Download the SP metadata from AWS IAM Identity Center:
   - Navigate to AWS IAM Identity Center
   - Go to Applications → Your Application → Actions → Edit configuration
   - Download the IAM Identity Center SAML metadata file

2. Save it in this directory as `aws-sso-sp-metadata.xml`

3. Reference it in your SAML provider configuration

### File Naming Convention

- `aws-sso-sp-metadata.xml` - AWS SSO metadata
- `salesforce-sp-metadata.xml` - Salesforce metadata
- `{service}-sp-metadata.xml` - Other service provider metadata

## Security Note

These files typically contain public information (endpoints, certificates) but
may include instance-specific IDs. They should not be committed to version
control if they contain organization-specific data.
