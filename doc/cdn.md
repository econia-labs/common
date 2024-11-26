# Setting up a CDN using AWS CloudFront

## Step 1: Create an S3 bucket

Use all default option, except:

- Under `Block Public Access settings for this bucket`:
  - Untick all check boxes.

## Step 2: Create a CloudFront distribution

- Under `Origin`:
  - Set `Origin domain` to the newly created bucket.
  - Set `Origin access` to `Origin access control settings`.
    - Click `Create new OAC`.
      - Make sure `Sign requests` is ticked.
- Under `Viewer > Viewer protocol policy`:
  - Set `Redirect HTTP to HTTPS`.
- Under `Cache key and origin requests`:
  - Set `Cache policy` to `CachingOptimized`.
  - Set `Origin request policy` to `CORS-S3origin`.
  - Set `Response headers policy` to `SimpleCORS`.
- Under `Web Application Firewall (WAF)`:
  - Tick `Enable security protections`.
    - Do not use `monitor mode`.
- Under `Settings » Supported HTTP versions`:
  - Tick `HTTP/2`.
  - Tick `HTTP/3`.

## Step 3: Update S3 bucket settings

After the distribution is created, AWS will display a notification.

This notification will tell you to copy paste JSON data into the bucket
settings.

Click the copy button, then proceed as instructed.

Search for your bucket, then go to `Permissions > Bucket policy` and paste the
JSON there.

## Step 4: Adding files to the CDN

To add files to the CDN, go to your S3 bucket.

In the `Objects` tab, hit the `Upload` button.

Once your files selected, before hitting `Upload` to confirm the upload, make
sure to expand `Properties`, and add `Metadata` as needed. `Metadata` allows
you to add headers to your files. For example, you can add a [`Cache-Control`]
header by setting `Type` to `System defined`, `Key` to `Cache-Control`, and
`Value` to whatever cache value you wish.

## Step 5: Accessing your files

To access your files, go to the CloudFront page of the CDN you just created.

In the `General` tab, under `Details`, you should see
`Distribution domain name`.

Your files are accessible at
`https://${Distribution domain name}/${File path in S3 bucket}`.

## Guidelines

It is not required to create multiple CDNs. If possible, use the one already
created. The creation of a new CDN should only happen if certain strict
requirements arise, like a CDN that requires authentication.

[`cache-control`]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
