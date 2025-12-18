# Introduction - Agent application deployment with Azure Web Apps

# Environment variables and vault secrets

Converting from json file to BASE64 encoded json:
- you get the json file from google cloud console
- several ways to convert to base64, one is via terminal: creates a minified version of the json file, which you can either upload to the app as a an environment variable, or store in a vault secret if using GitHub Actions for deployment.

  ```bash
  cat dinner-generator-project-[NEW_KEY_ID].json | jq -c . > key-min.json
  ```