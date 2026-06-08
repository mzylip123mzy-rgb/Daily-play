# Cloud Deployment

This project is ready to run on GitHub Actions.

## What is already in place

- `work/Send-DailyPlan.ps1` supports GitHub Actions environment variables.
- `.github/workflows/daily-plan.yml` schedules a daily run on `windows-latest`.
- The image generator keeps using `System.Drawing`, so Windows runners are required.

## Required repository secrets

Add these secrets in GitHub:

- `PUSHPLUS_TOKEN`
- `PUSHPLUS_SECRET_KEY`
- `PUSHPLUS_ENDPOINT`
- `PUSHPLUS_CHANNEL` (optional, defaults to `wechat`)

## Publish steps

1. Create a new GitHub repository.
2. Push this folder to that repository.
3. Add the secrets above.
4. Open the Actions tab and run `Daily Study Plan` once with `workflow_dispatch`.
5. Verify the workflow run succeeded and the WeChat message arrived.

## Notes

- The workflow uploads the generated PNG to `tmpfiles.org` and embeds that public URL in the PushPlus HTML message.
- If you want a stricter hosting option later, the upload step can be swapped to your own object storage bucket.

