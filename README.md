# Daily Study Plan Sender

This project generates a daily study-plan image and sends it through PushPlus as an HTML message.

## Cloud deployment

Use the GitHub Actions workflow in `.github/workflows/daily-plan.yml`.

Required repository secrets:

- `PUSHPLUS_TOKEN`
- `PUSHPLUS_SECRET_KEY`
- `PUSHPLUS_ENDPOINT`
- `PUSHPLUS_CHANNEL` if you want to override the default `wechat`

Notes:

- The workflow runs on `windows-latest` because the image generator uses `System.Drawing`.
- In GitHub Actions, the script pushes the generated PNG back to the repository and uses the GitHub raw URL in the PushPlus HTML message.
- You can run it manually from the GitHub Actions tab with `workflow_dispatch`.
