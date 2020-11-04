# packer-centos8-rancher

###
#Builds a Centos 8 Rancher Server. Deploys to VMware ESXI. Manages a permanent volume disk. Configures all network settings.
###

# Requirements

* VMWare Fusion. £3 from Ebay. £80 from VMWare.

  * https://www.vmware.com/uk/products/fusion.html

  * https://www.ebay.co.uk

* AWS Secret manager

  * https://aws.amazon.com/secrets-manager/

* sshpass

  * ```bash
    brew install esolitos/ipa/sshpass
    ```

* OVFTool 4.4

  * https://my.vmware.com/group/vmware/downloads/details?downloadGroup=OVFTOOL440&productId=967

# Instructions

## Create Secrets

### VM User Accounts

This packer build uses AWS Secrets Manager to manage the Secrets.

Assuming you haven't changed the json variable `admin_pass` etc...

Login to the AWS console, then create a "Other type of secret".

If you don't have an encryption key click the Link "Add new key" to goto KMS. Or just keep selecting keys from the dropdown until something works...

Hint: Click on `Plantext` to switch to JSON

Paste this in and set your own password;

```json
{
  "admin": "Here is my password",
  "root": "Here is my other password"
}
```

Click `Next`.

Set the `Secret Name` to `host/rancher/users`

Where `rancher` is the hostname/display name of the VM. This is arbitrary and only relates the secret paths, it's not used to set and hostname variable type stuff.

### Deploy host password

This is your ESXI root password.

You will also need to configure this as an AWS Secret.

Set `Secret name` to `host/sexiboy/user/root`

Assuming `sexiboy` is the hostname of your ESXI server. Again this is just used for a secret path and does not define the deployment host. This is set under another config item `deploy_host`.

```json
{
  "password": "My Root Password (This isn't actually my root password) Or IS IT???"
}
```
It doesn't have to be root. Just make sure it matches the `scripts/full_deploy.sh` variables values like so. These variables are not defined in the main JSON file for lazyness reasons.

```bash
ESXI_USER="root"
SECRET_ID="host/sexiboy/user/$ESXI_USER"
SECRET_KEY="password"
```
The `SECRET_KEY` does have to match the key in the AWS JSON Secret. Just leave it set to password!

## Export AWS Secret Manager ENV

To make AWS Secret Manager work you must set the ENV REGION like so.

```bash
export AWS_REGION=eu-west-1
```

Assuming your secrets are in Ireland. My stag do was is Ireland and that's where a lot of secrets are kept!

# Set variables in the json file

These are entirely up to you and pretty much self explanitory. Well kind of...

The VM is baked with a static network configuration that is defined in the json file. 

The VM is deployed to a defined DataStore and network. 

The build  creates and attaches a volume disk in within ESXI, just incase you want permanent storage.

When you redploy the BOOT DISK WILL BE DESTROYED WITH THE VM. The volume disk will not be destroyed. That's why it's there.

a varialbe `rancher_storage` can be set to `ephemeral` or `permanent`. This will shift the location of the Rancher config store.

Setting this variable will depend on how you deploy your Rancher config. If you are using the GUI set this to `permanent`.

# Build the build! 

```bash
packer build centos8-rancher.json
```

This also performs a full deployment to ESXI.

# Run deploy script manually

If you want to just deploy again wihtout building...

Please run ```scripts/full_deploy.sh``` from root dir

# When the build is over

The build does not make the filesystem on the ```volume``` disk

Make the filesystem yourself!!

This must only be performed once after the first deploy!

Login to your new Rancher VM.

```bash
mkfs.xfs /dev/sdb
mkdir /volumes
```