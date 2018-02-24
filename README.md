# EGL AWS S3 Bucket Size Utility 

This shell script reports the the size of AWS S3 buckets and writes it to JSON and CSV files

This utility produces output that:

* Answer the question: "What size are the AWS S3 buckets in our multiple AWS accounts?"
* Create an audit trail of AWS S3 bucket size 
* Is suitable for use in databases, spreadsheets, or reports

This utility provides S3 bucket size functionality unavailable in the AWS console or directly via the AWS CLI API. 

This utility can: 

* Capture the S3 bucket size for any time period in a single or all AWS accounts
* Write the S3 bucket sizes to JSON and CSV files in bytes, megabytes, gigabytes, and terabytes for each storage type (note: CSV is only the sum of all storage types, JSON includes sum and each storage type)  

## Getting Started

1. Instantiate a local or EC2 Linux instance
2. Install or update the AWS CLI utilities
    * The AWS CLI utilities are pre-installed on AWS EC2 Linux instances
    * To update on an AWS EC2 instance: `$ sudo pip install --upgrade awscli` 
3. Create an AWS CLI named profile that includes the required IAM permissions 
    * See the "[Prerequisites](#prerequisites)" section for the required IAM permissions
    * To create an AWS CLI named profile: `$ aws configure --profile MyProfileName`
    * AWS CLI named profile documentation is here: [Named Profiles](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
4. Install the [bash](https://www.gnu.org/software/bash/) shell
    * The bash shell is included in most distributions and is pre-installed on AWS EC2 Linux instances
5. Install [jq](https://github.com/stedolan/jq) 
    * To install jq on AWS EC2: `$ sudo yum install jq -y`
6. Download this utility script or create a local copy and run it on the local or EC2 Linux instance
    * Example: `$ bash ./aws-s3-size.sh -p AWS_CLI_profile -s 2018-02-12T02:00:00 -e 2018-02-12T03:59:59`  

## [Prerequisites](#prerequisites)

* [bash](https://www.gnu.org/software/bash/) - Linux shell 
* [jq](https://github.com/stedolan/jq) - JSON wrangler
* [AWS CLI](https://aws.amazon.com/cli/) - command line utilities (pre-installed on AWS AMIs) 
* AWS CLI profile with IAM permissions for the AWS CLI commands:
  * aws cloudwatch get-metric-statistics (used to pull S3 bucket size )
  * aws sts get-caller-identity (used to pull account number )
  * aws iam list-account-aliases (used to pull account alias )


## Deployment

To execute the utility:

  * Example: `$ bash ./aws-s3-size.sh -p AWS_CLI_profile -s start timestamp -e end timestamp`  

To directly execute the utility:  

1. Set the execute flag: `$ chmod +x aws-s3-size.sh`
2. Execute the utility  
    * Example: `$ ./aws-s3-size.sh -p AWS_CLI_profile -s start timestamp -e end timestamp`    

## Output

* JSON 'S3 bucket overall and each storage type size' per account file
* CSV 'S3 bucket overall size' per account file
* Info log (execute with the `-g y` parameter)  
  * Example: `$ bash ./aws-s3-size.sh -p AWS_CLI_profile -s start timestamp -e end timestamp -g y` 
* Console verbose mode (execute with the `-b y` parameter)  
  * Example: `$ bash ./aws-s3-size.sh -p AWS_CLI_profile -s start timestamp -e end timestamp -b y`  

## Contributing

Please read [CONTRIBUTING.md](https://github.com/Enterprise-Group-Ltd/aws-s3-size/blob/master/CONTRIBUTING.md) for the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. 

## Authors

* **Douglas Hackney** - [dhackney](https://github.com/dhackney)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Enterprise-Group-Ltd/aws-s3-size/blob/master/LICENSE) file for details

## Acknowledgments

* Key jq answers by [jq170727](https://stackoverflow.com/users/8379597/jq170727) 
* [Progress bar](https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script)  
* [Dynamic headers fprint](https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash)
* [Menu](https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script)
* Countless other jq and bash/shell man pages, Q&A, posts, examples, tutorials, etc. from various sources  

