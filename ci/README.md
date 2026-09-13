# CI

`flutter_ci.yml` is a GitHub Actions workflow (analyze → test → debug APK).

To enable it, move it into place (requires a token/account with the
`workflows` permission):

```bash
mkdir -p .github/workflows
mv ci/flutter_ci.yml .github/workflows/flutter_ci.yml
git add -A && git commit -m "Enable CI workflow" && git push
```
