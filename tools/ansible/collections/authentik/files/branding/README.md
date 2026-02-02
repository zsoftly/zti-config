# Branding Assets

Place your custom branding files in this directory for Authentik theming.

## Required Files

- `logo.png` - Your organization logo (recommended: 200x60px)
- `favicon.png` - Browser favicon (recommended: 32x32px)
- `login-background.png` - Login page background image (recommended:
  1920x1080px)

## Usage

These files are uploaded to Authentik via the branding role
(`roles/11_branding`).

Update the role defaults in `roles/11_branding/defaults/main.yml` to reference
your files.
