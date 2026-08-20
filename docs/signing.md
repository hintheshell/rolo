# Signing

Rolo uses a stable self-signed code-signing identity named `Rolo Self-Signed`. It is not an Apple
Developer ID, but using the same identity for every build keeps the app's code requirement stable so
macOS does not treat each update as an unrelated Accessibility client.

The same identity signs local builds and GitHub releases. Generate it once, import it into the login
keychain, and upload the generated PKCS#12 bundle to the Rolo repository as encrypted Actions secrets.

## Create and import the identity

```sh
ROLO_SIGNING_DIR="$(mktemp -d)"
ROLO_KEYCHAIN="$(security login-keychain | tr -d '"')"
ROLO_P12_PASSWORD="$(openssl rand -hex 32)"

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$ROLO_SIGNING_DIR/key.pem" -out "$ROLO_SIGNING_DIR/cert.pem" \
  -subj "/CN=Rolo Self-Signed" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"

openssl pkcs12 -legacy -export \
  -inkey "$ROLO_SIGNING_DIR/key.pem" -in "$ROLO_SIGNING_DIR/cert.pem" \
  -name "Rolo Self-Signed" -out "$ROLO_SIGNING_DIR/rolo.p12" \
  -passout "pass:$ROLO_P12_PASSWORD"

security import "$ROLO_SIGNING_DIR/rolo.p12" -k "$ROLO_KEYCHAIN" \
  -P "$ROLO_P12_PASSWORD" -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$ROLO_KEYCHAIN" \
  "$ROLO_SIGNING_DIR/cert.pem"
security find-identity -p codesigning "$ROLO_KEYCHAIN" | grep -F "Rolo Self-Signed"
```

## Configure GitHub release secrets

Run this before deleting the temporary directory created above:

```sh
gh api --method PUT repos/hintheshell/rolo/environments/release
base64 -i "$ROLO_SIGNING_DIR/rolo.p12" | tr -d '\n' \
  | gh secret set SIGNING_P12_BASE64 --env release --repo hintheshell/rolo
gh secret set SIGNING_P12_PASSWORD --env release --repo hintheshell/rolo \
  --body "$ROLO_P12_PASSWORD"
```

The signing secrets are environment-scoped, not repository-scoped. Only a job that explicitly uses
the `release` Environment receives them; `.github/workflows/release.yml` is the sole such job. The
Environment's deployment branch policy permits only `main`. The private key ACL likewise names only
`/usr/bin/codesign` and must not use `security import -A`.

After both secrets exist, delete the temporary directory securely enough for the local threat model
and unset `ROLO_P12_PASSWORD`. Losing the certificate requires a new signing identity and users will
need to grant Accessibility again; losing only the GitHub secrets does not, provided the original
identity remains in the login keychain.

## Homebrew tap deploy key

The release workflow uses `HOMEBREW_TAP_DEPLOY_KEY`, an SSH deploy key that has write access only to
`hintheshell/homebrew-rolo`. The matching public key belongs on that repository under
**Settings → Deploy keys** with write access enabled. The private key is stored only as an Actions
secret on `hintheshell/rolo`.

## Quarantine

macOS quarantines internet downloads and blocks a self-signed app as an unidentified developer. The
Homebrew cask removes quarantine in `postflight`. A direct DMG installation needs this once:

```sh
xattr -dr com.apple.quarantine "/Applications/Rolo.app"
```
