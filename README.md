# Project 2 Template

## Initial Set up

The following steps should only need to be done once:

### Set Environment Variable

Add the following to your `.bash_profile` script, or similar for your shell:

```sh
# If your ucsb email is user_1@ucsb.edu, then YOUR_ACCOUNT_NAME is user-1
# Note: If you have an underscore in your account name, please replace with a hypen.
export CS291_ACCOUNT=YOUR_ACCOUNT_NAME
```

### Install `gcloud` tool

Follow the instructions here:
https://cloud.google.com/sdk/docs/#install_the_latest_cloud_tools_version_cloudsdk_current_version

### Authenticate with Google

Make sure you select your `@ucsb.edu` account when authenticating.

```sh
gcloud auth login
```

### Verify the above works

```sh
gcloud projects describe cs291-f19
```

The above should produce the following output:

```
createTime: '2019-07-18T19:28:19.613Z'
lifecycleState: ACTIVE
name: cs291-f19
parent:
  id: '867683236978'
  type: organization
projectId: cs291-f19
projectNumber: '689092254566'
```

### Create Application Default Credentials

Again, make sure you select your @ucsb.edu account when authenticating.

```sh
gcloud auth application-default login
```

### Install Docker

Follow the instructions here: https://www.docker.com/products/docker-desktop

### Link Docker and Gcloud

```sh
gcloud auth configure-docker
```

## Develop Locally

Edit your file however you want then follow the next two steps to test your
application:

### Build Container

```sh
docker build -t us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT} .
```

### Run Locally

```sh
docker run -it --rm \
  -p 3000:3000 \
  -v ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json \
  us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT}
```

### Test Using CURL

```sh
curl -D- localhost:3000/
```

The default application should provide output that looks like the following:

```http
HTTP/1.1 200 OK
Content-Type: text/html;charset=utf-8
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Length: 12

Hello World
```

## Production Deployment

Each time you want to deploy your application to Google Cloud Run, perform the
following two steps:

### Push Container to Google Container Registry

```sh
docker push us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT}
```

### Deploy to Google Cloud Run

```sh
gcloud beta run deploy \
  --allow-unauthenticated \
  --concurrency 80 \
  --image us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT} \
  --memory 128Mi \
  --platform managed \
  --project cs291-f19 \
  --region us-central1 \
  --service-account project2@cs291-f19.iam.gserviceaccount.com \
  --set-env-vars RACK_ENV=production \
  ${CS291_ACCOUNT}
```

The last line of output should look similar to the following:

```
Service [{ACCOUNT_NAME}] revision [{ACCOUNT_NAME}-00018] has been deployed and is serving 100 percent of traffic at https://{ACCOUNT_NAME}-fi6eeq56la-uc.a.run.app
```

### View Logs

1. Browse to: https://console.cloud.google.com/run?project=cs291-f19

2. Click on the service with your ACCOUNT_NAME

3. Click on "LOGS"

4. Browse logs, and consider changing the filter to "Warning" to find more pressing issues.

## Resources

- https://cloud.google.com/run/docs/quickstarts/build-and-deploy
- https://googleapis.dev/ruby/google-cloud-storage/latest/index.html

## Possible Errors

### invalid reference format

Re-run the `export` command.
