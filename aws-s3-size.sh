#! /bin/bash
#
#
#
# ------------------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2018 Enterprise Group, Ltd.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ------------------------------------------------------------------------------------
# 
# File: aws-s3-size.sh
#
script_version=0.0.45   
#
#  Dependencies:
#  - 'aws-services-snapshot-driver.txt' or custom driver file containing AWS describe/list commands 
#  - 'aws-services-snapshot-driver-global.txt' containing AWS global services (not limited to an AWS region) 
#  - bash shell
#  - jq - JSON wrangler https://stedolan.github.io/jq/
#  - AWS CLI tools (pre-installed on AWS AMIs) 
#  - AWS CLI profile with IAM permissions for the AWS CLI command:
#    - aws sts get-caller-identity (used to pull account number )
#    - aws iam list-account-aliases (used to pull account alias )
#  - AWS CLI profile with IAM permissions for the AWS CLI command:
#    'cloudwatch get-metric-statistics' (used to pull the S3 bucket sizes)
#
#  Sample IAM policy JSON for "sts:GetCallerIdentity"
#
#       {
#       "Version": "2012-10-17",
#       "Statement": 
#       	{
#       	"Effect": "Allow",
#       	"Action": "sts:GetCallerIdentity",
#       	"Resource": "*"
#       	}
#       }
#
#
# Sample IAM policy JSON for "iam:ListAccountAliases"
#
#       {
#       "Version": "2012-10-17",
#       "Statement": 
#       	{
#       	"Effect": "Allow",
#       	"Action": "iam:ListAccountAliases",
#       	"Resource": "*"
#       	}
#       }
#
#
#
# Tested on: 
#   Windows Subsystem for Linux (WSL) 
#     OS Build: 15063.540
#     bash.exe version: 10.0.15063.0
#     Ubuntu 16.04
#     GNU bash, version 4.3.48(1)
#     jq 1.5-1-a5b5cbe
#     aws-cli/1.11.134 Python/2.7.12 Linux/4.4.0-43-Microsoft botocore/1.6.1
#   
#   AWS EC2
#     Amazon Linux AMI release 2017.03 
#     Linux 4.9.43-17.38.amzn1.x86_64 
#     GNU bash, version 4.2.46(2)
#     jq-1.5
#     aws-cli/1.11.133 Python/2.7.12 Linux/4.9.43-17.38.amzn1.x86_64 botocore/1.6.0
#
#
# By: Douglas Hackney
#     https://github.com/dhackney   
# 
# Type: AWS utility
# Description: 
#   This shell script snapshots the current state of AWS resources and writes it to JSON files
#
#
# Roadmap:
#  * summary report
# 
#
###############################################################################
# 
# set the environmental variables 
#
set -o pipefail 
#
###############################################################################
# 
#
# initialize the script variables
#
echo ""
echo "initialize the script variables"
echo ""
aws_account=""
aws_account_alias=""
bucket_bytes=""
bucket_gigabytes=0
bucket_list=""
bucket_megabytes=0
bucket_name=""
bucket_name_2=""
bucket_name_feed=""
bucket_size_json_edit=""
bucket_size_json_results=""
bucket_size_name_bytes=""
bucket_size_TB_GB_MB_B_build=""
bucket_terabytes=0
cli_profile=""
cli_profile_file_check_line=""
cli_profile_file_check_line_strip=""
count_bucket_list=0
count_cli_profile=0
count_cli_profile_file_check_line=0
count_script_version_length=0
count_storage_type=0
count_tasks_loop=0
count_tasks_this_file=0
count_tasks_this_file_all=0
count_tasks_this_file_end=0
count_tasks_this_file_increment=0
count_tasks_this_file_increment_all=0
count_tasks_this_file_non_loop=0
count_text_bar_header=0
count_text_bar_menu=0
count_text_block_length=0
count_text_header_length=0
count_text_side_length_header=0
count_text_side_length_menu=0
count_text_width_header=0
count_text_width_menu=0
counter_bucket_list=0
counter_cli_profile=0
counter_cli_profile_task_display=0
counter_storage_type=0
counter_tasks_this_file=0
date_file="$(date +"%Y-%m-%d-%H%M%S")"
date_now="$(date +"%Y-%m-%d-%H%M%S")"
_empty=""
_empty_task=""
_empty_task_sub=""
error_line_aws=""
error_line_jq=""
error_line_pipeline=""
error_line_psql=""
feed_write_log=""
file_driver=""
_fill=""
_fill_task=""
_fill_task_sub=""
full_path=""
let_done=""
let_done_task=""
let_done_task_sub=""
let_left=""
let_left_task=""
let_left_task_sub=""
let_progress=""
let_progress_task=""
let_progress_task_sub=""
log_suffix=""
logging=""
parameter1=""
paramter2=""
storage_type=""
tasks_code=""
tasks_loop_line_start=0
tasks_loop_line_end=0
text_bar_header_build=""
text_bar_menu_build=""
text_header=""
text_header_bar=""
text_menu=""
text_menu_bar=""
text_side_header=""
text_side_menu=""
this_file=""
this_log=""
this_log_file=""
this_log_file_errors=""
this_log_file_errors_full_path=""
this_log_file_full_path=""
this_log_temp_file_full_path=""
this_path=""
this_path_temp=""
this_summary_report=""
this_summary_report_full_path=""
this_user=""
this_utility_acronym=""
this_utility_filename_plug=""
thislogdate=""
timestamp_end=""
timestamp_period=""
timestamp_start=""
verbose=""
write_file=""
write_file_clean=""
write_file_full_path=""
write_file_raw=""
write_file_service_names=""
write_file_service_names_unique=""
write_path=""
#
#
#
#
#
##############################################################################################################33
#                           Function definition begin
##############################################################################################################33
#
#
# Functions definitions
#
#######################################################################
#
#
#
#######################################################################
#
#
# function to display the Usage  
#
#
function fnUsage()
{
    echo ""
    echo " ----------------------------------------- AWS S3 Bucket Size utility usage ------------------------------------------"
    echo ""
    echo " This utility reports the the size of AWS S3 buckets  "  
    echo ""
    echo " This script will: "
    echo " * Capture the average size of AWS S3 buckets for a given time period "
    echo " * Write the average size of AWS S3 buckets to a JSON file for each account  "
    echo " * Write the size of AWS S3 buckets in Bytes, Megabytes, Gigabytes, and Terabytes to a CSV file for each account  "  
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " Usage:"
    echo "         aws-s3-size.sh -p AWS_CLI_profile -s start timestamp -e end timestamp "
    echo ""
    echo "         Optional parameters: -t storage type -d period "
    echo ""
    echo "         Example: aws-s3-size.sh -p prod -s 2018-02-12T02:00:00 -e 2018-02-12T03:59:59"
    echo ""
    echo "         Note: AWS accounts are determined by the AWS CLI profile "
    echo ""
    echo " Where: "
    echo "  -p - Name of the AWS CLI cli_profile (i.e. what you would pass to the --profile parameter in an AWS CLI command)"
    echo "       or the name of a text file containing a list of AWS CLI profiles for multiple accounts"
    echo "         Example: -p myAWSCLIprofile "
    echo "         Example: -p s3-size-profile-driver-file.txt "
    echo ""    
    echo "  -s - The GMT/UTC/Zulu timestamp to begin the bucket average size calculation in the format: YYYY-MM-DDTHH:MM:SS  "
    echo "       Example: -s 2018-02-12T00:00:00"
    echo ""    
    echo "  -e - The GMT/UTC/Zulu timestamp to end the bucket average size calculation in the format: YYYY-MM-DDTHH:MM:SS  "
    echo "       Example: -e 2018-02-12T01:00:00"
    echo ""    
    echo "  -d - The period in seconds to sample the S3 bucket size. Default is 3600. Valid entries follow."
    echo "       Example: -d 60"
    echo "       Example: -d 300"
    echo "       Example: -d 3600"
    echo "       Documentation is here: https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-statistics.html"
    echo ""    
    echo "  -t - The S3 storage type to measure. Default is 'all'. Valid entries follow. "
    echo "       Example: -t all"
    echo "       Example: -t StandardStorage"
    echo "       Example: -t StandardIAStorage"
    echo "       Example: -t ReducedRedundancyStorage"
    echo "       Documentation is here: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/s3-metricscollected.html"
    echo ""        
    echo ""        
    echo "  -b - Verbose console output. Set to 'y' for verbose console output. Temp files are not deleted. "
    echo "         Example: -b y "
    echo ""
    echo "  -g - Logging on / off. Default is off. Set to 'y' to create an info log. Set to 'z' to create a debug log. "
    echo "       Note: logging mode is slower and debug log mode will be very slow and resource intensive on large jobs. "
    echo "         Example: -g y "
    echo ""
    echo "  -h - Display this message"
    echo "         Example: -h "
    echo ""
    echo "  ---version - Display the script version"
    echo "         Example: --version "
    echo ""
    echo ""
    exit 1
}
#
#######################################################################
#
#
# function to echo the progress bar to the console  
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBar() 
{
    #
    # Process data
            let _progress=(${1}*100/"${2}"*100)/100
            let _done=(${_progress}*4)/10
            let _left=40-"$_done"
    # Build progressbar string lengths
            _fill="$(printf "%${_done}s")"
            _empty="$(printf "%${_left}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r          Overall Progress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}
#
#######################################################################
#
#
# function to update the task progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTask() 
{
    #    
    # Process data
            let _progress_task=(${1}*100/"${2}"*100)/100
            let _done_task=(${_progress_task}*4)/10
            let _left_task=40-"$_done_task"
    # Build progressbar string lengths
            _fill_task="$(printf "%${_done_task}s")"
            _empty_task="$(printf "%${_left_task}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r          Account Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"
}
#
#######################################################################
#
#
# function to update the subtask progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTaskSub() 
{
    #    
    # Process data
            let _progress_task_sub=(${1}*100/"${2}"*100)/100
            let _done_task_sub=(${_progress_task_sub}*4)/10
            let _left_task_sub=40-"$_done_task_sub"
    # Build progressbar string lengths
            _fill_task_sub="$(printf "%${_done_task_sub}s")"
            _empty_task_sub="$(printf "%${_left_task_sub}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r   Account Bucket Progress : [${_fill_task_sub// /#}${_empty_task_sub// /-}] ${_progress_task_sub}%%"
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskDisplay() 
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnProgressBarTaskDisplay' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTask "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskSubDisplay() 
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnProgressBarTaskSubDisplay' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTaskSub "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo the header to the console  
#
function fnHeader()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnHeader' "
    fnWriteLog ${LINENO} ""
    #    
    clear
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------"    
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "$text_header"    
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBar ${counter_tasks_this_file} ${count_tasks_this_file}
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo to the console and write to the log file 
#
function fnWriteLog()
{
    # clear IFS parser
    IFS=
    # write the output to the console
    fnOutputConsole "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    # if logging is enabled, then write to the log
    if [[ ("$logging" = "y") || ("$logging" = "z") || ("$logging" = "x")   ]] 
        then
            # write the output to the log
            fnOutputLog "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    fi 
    # reset IFS parser to default values 
    unset IFS
}
#
#######################################################################
#
#
# function to echo to the console  
#
function fnOutputConsole()
{
   #
    # console output section
    #
    # test for verbose
    if [ "$verbose" = "y" ] ;  
        then
            # if verbose console output then
            # echo everything to the console
            #
            # strip the leading 'level_0'
                if [ "$2" = "level_0" ] ;
                    then
                        # if the line is tagged for display in non-verbose mode
                        # then echo the line to the console without the leading 'level_0'     
                        echo " Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                    else
                        # if a normal line echo all to the console
                        echo " Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                fi
    else
        # test for minimum console output
        if [ "$2" = "level_0" ] ;
            then
                # echo ""
                # echo "console output no -v: the logic test for level_0 was true"
                # echo ""
                # if the line is tagged for display in non-verbose mode
                # then echo the line to the console without the leading 'level_0'     
                echo " "$3" "$4" "$5" "$6" "$7" "$8" "$9""
        fi
    fi
    #
    #

}  

#
#######################################################################
#
#
# function to write to the log file 
#
function fnOutputLog()
{
    # log output section
    #
    # load the timestamp
    thislogdate="$(date +"%Y-%m-%d-%H:%M:%S")"
    #
    # ----------------------------------------------------------
    #
    # normal logging
    # 
    # append the line to the log variable
    # the variable is written to the log file on exit by function fnWriteLogFile
    #
    #
    if [ "$2" = "level_0" ] ;
        then
            # if the line is tagged for logging in non-verbose mode
            # then write the line to the log without the leading 'level_0'     
            this_log+="$(echo "${thislogdate} Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
        else
            # if a normal line write the entire set to the log
            this_log+="$(echo "${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
    fi
    #
    # append the new line  
    # do not quote this variable
    this_log+=$'\n'
    #
    #  
    # ---------------------------------------------------------
    #
    # 'use this for debugging' - debug logging
    #
    # if the script is crashing and you cannot debug it from the 'info' mode log produced by -g y, 
    # then enable 'verbose' console output and 'debug' logging mode
    #
    # note that the 'debug' form of logging is VERY slow on big jobs
    # 
    # use parameters: -b y -g z 
    #
    # if the script crashes before writing out the log you can scroll back in the console to 
    # identify the line number where the problem is located 
    #
    # 
}
#
#######################################################################
#
#
# function to append the log variable to the temp log file 
#
function fnWriteLogTempFile()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnWriteLogTempFile' "
    fnWriteLog ${LINENO} ""
    # 
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Appending the log variable to the temp log file"
    fnWriteLog ${LINENO} "" 
	feed_write_log="$(echo "$this_log" >> "$this_log_temp_file_full_path" 2>&1)"
	#
	# check for command / pipeline error(s)
	if [ "$?" -ne 0 ]
	    then
	        #
	        # set the command/pipeline error line number
	        error_line_pipeline="$((${LINENO}-7))"
	        #
	        #
	        fnWriteLog ${LINENO} level_0 ""
	        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
	        feed_write_log="$(echo "$feed_write_log")"
	        fnWriteLog ${LINENO} level_0 "$feed_write_log"
	        fnWriteLog ${LINENO} level_0 ""
	        #                                                    
	        # call the command / pipeline error function
	        fnErrorPipeline
	        #
	        #
	fi
	#
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
    # empty the temp log variable
    this_log=""
    #
}
#
#######################################################################
#
#
# function to write log variable to the log file 
#
function fnWriteLogFile()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnWriteLogFile' "
    fnWriteLog ${LINENO} ""
    #     
    # append the temp log file onto the log file
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Writing temp log to log file"
    fnWriteLog ${LINENO} "Value of variable 'this_log_temp_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_temp_file_full_path"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Value of variable 'this_log_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_file_full_path"
    fnWriteLog ${LINENO} ""   
    # write the contents of the variable to the temp log file
    #
    fnWriteLogTempFile
    #
    if [[ "$aws_account" != "" ]]
    	then 
		    cat "$this_log_temp_file_full_path" >> "$this_log_file_full_path"
		    echo "" >> "$this_log_file_full_path"
		    echo "Log end" >> "$this_log_file_full_path"
		    # delete the temp log file
		    rm -f "$this_log_temp_file_full_path"
		elif [[ "$aws_account" = "" ]]
			then
			# echo "AWS account is empty. Preserving temp log file."
			# echo "Temp log file is here: "
			# echo "$this_log_temp_file_full_path"
			echo ""
	fi
}
#
##########################################################################
#
#
# function to delete the work files 
#
function fnDeleteWorkFiles()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnDeleteWorkFiles' "
    fnWriteLog ${LINENO} ""
    #   
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in delete work files "
    fnWriteLog ${LINENO} "value of variable 'verbose': "$verbose" "
    fnWriteLog ${LINENO} ""
        if [ "$verbose" != "y" ] ;  
            then
                # if not verbose console output then delete the work files
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "In non-verbose mode: Deleting work files"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"-* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"_* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path' "$this_log_file_full_path" "
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -r -f "$this_path_temp" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                #
                # check for error file; if exists 
                # if no errors, then delete the error log file
                if [[ -f "$this_log_file_errors_full_path" ]]
                	then 
		                count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
		                if (( "$count_error_lines" < 3 ))
		                    then
		                        rm -f "$this_log_file_errors_full_path"
		                fi  
		        fi
            else
                # in verbose mode so preserve the work files 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "In verbose mode: Preserving work files "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "work files are here: "$this_path" "
                fnWriteLog ${LINENO} level_0 ""                
        fi       
}
#
##########################################################################
#
#
# function to handle command or pipeline errors 
#
function fnErrorPipeline()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorPipeline' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Command or Command Pipeline Error "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " System Error while running the previous command or pipeline "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_pipeline" "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
    fi
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function for AWS CLI errors 
#
function fnErrorAws()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorAws' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " AWS Error while executing AWS CLI command"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the AWS error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_aws" "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$write_path"/ "
            fnWriteLog ${LINENO} level_0 " "$this_log_file" "
    fi 
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function for jq errors 
#
function fnErrorJq()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorJq' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_jq" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " There was a jq error while processing JSON "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the jq error message above "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$write_path"/ "
            fnWriteLog ${LINENO} level_0 " "$this_log_file" "
    fi
    fnWriteLog ${LINENO} level_0 " The log will also show the jq error message and other diagnostic information "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log is located here: "
    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function to check for valid date prameter entry
#
fnDateValid() {
   if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] && date -d "$1">/dev/null 2>&1
   	then
   		fnWriteLog ${LINENO} ""
	    fnWriteLog ${LINENO} "Valid date entry"
	    fnWriteLog ${LINENO} ""
	   else
	    fnWriteLog ${LINENO} "Invalid date entry"
	    fnWriteLog ${LINENO} ""
   	    clear
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid date: "$1" " 
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  Dates must be in the foramt YYYY-MM-DDTHH:mm:SS "
	    fnWriteLog ${LINENO} level_0 "  Example: 2018-02-18T23:59:59 "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnUsage
	fi;
}
#
##########################################################################
#
#
# function to log non-fatal errors 
#
function fnErrorLog()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorLog' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error message: "
    fnWriteLog ${LINENO} level_0 " "$feed_write_log""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------" 
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path"         
    echo "" >> "$this_log_file_errors_full_path" 
    echo " Error message: " >> "$this_log_file_errors_full_path" 
    echo " "$feed_write_log"" >> "$this_log_file_errors_full_path" 
    echo "" >> "$this_log_file_errors_full_path"
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path" 
}
#
##########################################################################
#
#
# function to increment the task counter 
#
function fnCounterIncrementTask()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCounterIncrementTask' "
    fnWriteLog ${LINENO} ""
    #      
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "incrementing the task counter"
    counter_tasks_this_file="$((counter_tasks_this_file+1))" 
    fnWriteLog ${LINENO} "value of variable 'counter_tasks_this_file': "$counter_tasks_this_file" "
    fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file': "$count_tasks_this_file" "
    fnWriteLog ${LINENO} ""
}
#
##############################################################################################################33
#                           Function definition end
##############################################################################################################33
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} "enable logging to capture initial segments "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
logging="y"
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} "build the menu and header text line and bars "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
text_header='AWS S3 Bucket Size utility v'
count_script_version_length=${#script_version}
count_text_header_length=${#text_header}
count_text_block_length=$(( count_script_version_length + count_text_header_length ))
count_text_width_menu=104
count_text_width_header=83
count_text_side_length_menu=$(( (count_text_width_menu - count_text_block_length) / 2 ))
count_text_side_length_header=$(( (count_text_width_header - count_text_block_length) / 2 ))
count_text_bar_menu=$(( (count_text_side_length_menu * 2) + count_text_block_length + 2 ))
count_text_bar_header=$(( (count_text_side_length_header * 2) + count_text_block_length + 2 ))
#
# source and explanation for the following use of printf is here: https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
text_bar_menu_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_menu")  )"
text_bar_header_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_header")  )"
text_side_menu="$(printf '%0.s-' $(seq 1 "$count_text_side_length_menu")  )"
text_side_header="$(printf '%0.s-' $(seq 1 "$count_text_side_length_header")  )"
text_menu="$(echo "$text_side_menu"" ""$text_header""$script_version"" ""$text_side_menu")"
text_menu_bar="$(echo "$text_bar_menu_build")"
text_header="$(echo " ""$text_side_header"" ""$text_header""$script_version"" ""$text_side_header")"
text_header_bar="$(echo " ""$text_bar_header_build")"
# 
###########################################################################################################################
#
#
# display initializing message
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display initializing message "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
clear
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This utility writes the size of AWS S3 buckets to JSON and CSV files "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This script will: "
fnWriteLog ${LINENO} level_0 " * Capture the average size of AWS S3 buckets for a given time period "
fnWriteLog ${LINENO} level_0 " * Write the average size of AWS S3 buckets to a JSON file for each account  "
fnWriteLog ${LINENO} level_0 " * Write the size of AWS S3 buckets in Bytes, Megabytes, Gigabytes, and "
fnWriteLog ${LINENO} level_0 "   Terabytes to a CSV file for each account  "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Please wait  "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Depending on connection speed and AWS API response, this can take " 
fnWriteLog ${LINENO} level_0 "  from a few seconds to a few minutes "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Status messages will appear below"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
#
###################################################
#
#
# check command line parameters 
# check for -h
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters "
fnWriteLog ${LINENO} " check for -h "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$1" = "-h" ]] 
    then
        clear
        fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# check for --version
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters "
fnWriteLog ${LINENO} " check for --version "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$1" = "--version" ]]  
    then
        clear 
        echo ""
        echo "'AWS S3 Size' script version: "$script_version" "
        echo ""
        exit 
fi
#
###################################################
#
#
# check command line parameters 
# if less than 2, then display the Usage
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters "
fnWriteLog ${LINENO} " if count of parameters is less than 2, then display the error message and useage "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$#" -lt 6 ]]  
	then
	    clear
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  You must provide a profile name, begin timestamp, and end timestamp: -p -s -e "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -s 2018-02-12T02:00:00 -e 2018-02-12T03:59:59 "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# if too many parameters, then display the error message and useage
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters "
fnWriteLog ${LINENO} " if too many parameters, then display the error message and useage "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$#" -gt 14 ]] 
	then
	    clear
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  ERROR: You entered too many parameters" 
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  You must provide only one value for all parameters: -p -s -e -d -t  "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -s 2018-02-12T02:00:00 -e 2018-02-12T03:59:59 -d 300 -t StandardStorage"
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnUsage
fi
#
###################################################
#
#
# log the parameter values 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " log the parameter values "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of parameter '1' "$1" "
fnWriteLog ${LINENO} "value of parameter '2' "$2" "
fnWriteLog ${LINENO} "value of parameter '3' "$3" "
fnWriteLog ${LINENO} "value of parameter '4' "$4" "
fnWriteLog ${LINENO} "value of parameter '5' "$5" "
fnWriteLog ${LINENO} "value of parameter '6' "$6" "
fnWriteLog ${LINENO} "value of parameter '7' "$7" "
fnWriteLog ${LINENO} "value of parameter '8' "$8" "
fnWriteLog ${LINENO} "value of parameter '9' "$9" "
fnWriteLog ${LINENO} "value of parameter '10' "${10}" "
fnWriteLog ${LINENO} "value of parameter '11' "${11}" "
fnWriteLog ${LINENO} "value of parameter '12' "${12}" "
fnWriteLog ${LINENO} "value of parameter '13' "${13}" "
fnWriteLog ${LINENO} "value of parameter '14' "${14}" "
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " load the main loop variables from the command line parameters  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
while getopts "p:s:e:d:t:b:g:h" opt; 
    do
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable '@': "$@" "
        fnWriteLog ${LINENO} "value of variable 'opt': "$opt" "
        fnWriteLog ${LINENO} "value of variable 'OPTIND': "$OPTIND" "
        fnWriteLog ${LINENO} ""   
        #     
        case "$opt" in
        p)
            cli_profile_param="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -p 'cli_profile_param': "$cli_profile_param" "
        ;;
        s)
            timestamp_start="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -s 'timestamp_start': "$timestamp_start" "
        ;; 
        e)
            timestamp_end="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -e 'timestamp_end': "$timestamp_end" "
        ;; 
        d)
            timestamp_period="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -d 'timestamp_period': "$timestamp_period" "
        ;; 
        t)
            storage_type="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -t 'storage_type': "$storage_type" "
        ;; 
        b)
            verbose="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -b 'verbose': "$verbose" "
        ;;  
        g)
            logging="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        h)
            fnUsage
        ;;   
        \?)
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "invalid parameter entry "
            fnWriteLog ${LINENO} "value of variable 'OPTARG': "$OPTARG" "
            clear
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "  ERROR: You entered an invalid parameter." 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "  Parameters entered: "$@""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnUsage
        ;;
    esac
done
#
###################################################
#
#
# check logging variable 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check logging variable   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# disable logging if not set by the -g parameter 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " disable logging if not set by the -g parameter   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "if logging not enabled by parameter, then disabling logging "
if [[ ("$logging" != "y") ]] 
    then 
        if [[ ("$logging" != "z") ]]  
            then
                logging="n"
        fi  # end test for logging = z
fi  # end test for logging = y
#
###################################################
#
#
# set the log suffix parameter 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " set the log suffix parameter   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$logging" = 'y' ]] 
    then 
        log_suffix='info'
elif [[ "$logging" = 'z' ]] 
    then 
        log_suffix='debug'
fi  # end test logging variable and set log suffix 
#
###################################################
#
#
# parameter raw values - pre-default
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " parameter raw values - pre-default  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "values of input variables prior to set defaults "
# 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile_param': ""$cli_profile_param" 
fnWriteLog ${LINENO} "value of variable 'timestamp_start': ""$timestamp_start" 
fnWriteLog ${LINENO} "value of variable 'timestamp_end': ""$timestamp_end" 
fnWriteLog ${LINENO} "value of variable 'timestamp_period': ""$timestamp_period" 
fnWriteLog ${LINENO} "value of variable 'storage_type': ""$storage_type" 
fnWriteLog ${LINENO} "value of variable 'verbose' "$verbose" "
fnWriteLog ${LINENO} "value of variable 'logging' "$logging" "
fnWriteLog ${LINENO} "value of variable 'log_suffix' "$log_suffix" "
fnWriteLog ${LINENO} ""
#
###############################################################################
# 
#
# set the parameter defaults
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " set the parameter defaults  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
# set period to one hour
if [[ "$timestamp_period" = "" ]] 
	then 
		timestamp_period=3600
fi
#
# set storage type to all types
if [[ "$storage_type" = "" ]] 
	then 
		storage_type="all"
fi
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'timestamp_period':"
fnWriteLog ${LINENO} "$timestamp_period" 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'storage_type':"
fnWriteLog ${LINENO} "$storage_type" 
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# parameter post-default values
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " parameter post-default values  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "values of input variables after set defaults, prior to validation  "
# 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile_param': ""$cli_profile_param" 
fnWriteLog ${LINENO} "value of variable 'timestamp_start': ""$timestamp_start" 
fnWriteLog ${LINENO} "value of variable 'timestamp_end': ""$timestamp_end" 
fnWriteLog ${LINENO} "value of variable 'timestamp_period': ""$timestamp_period" 
fnWriteLog ${LINENO} "value of variable 'storage_type': ""$storage_type" 
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# check command line parameters 
# check for valid start amd emd date entry
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters  "
fnWriteLog ${LINENO} " check for valid start amd emd date entry  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} " check for valid start date entry  "
fnDateValid "$timestamp_start"
#
fnWriteLog ${LINENO} " check for valid emd date entry  "
fnDateValid "$timestamp_end"
#
###################################################
#
#
# check command line parameters 
# check for valid period
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters  "
fnWriteLog ${LINENO} " check for valid period  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$timestamp_period" =~ ^(60|600|3600)$ ]]
	then
    fnWriteLog ${LINENO} "valid timestamp period parameter: "$timestamp_period" "
else
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "invalid timestamp period parameter entry: "$timestamp_period" "
    fnWriteLog ${LINENO} ""
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid Timestamp Period  parameter." 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Parameter entered: "$timestamp_period""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Valid timestamp periods are:"
    fnWriteLog ${LINENO} level_0 "      60"
    fnWriteLog ${LINENO} level_0 "     600"
    fnWriteLog ${LINENO} level_0 "    3600"   
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# check for valid storage type
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters  "
fnWriteLog ${LINENO} " check for valid storage type  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$storage_type" =~ ^(all|StandardStorage|StandardIAStorage|ReducedRedundancyStorage)$ ]]
	then
    fnWriteLog ${LINENO} "valid storage type parameter: "$storage_type" "
else
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "invalid storage type parameter entry: "$storage_type" "
    fnWriteLog ${LINENO} ""
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid storage type parameter." 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Parameter entered: "$storage_type""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Valid storage types are:"
    fnWriteLog ${LINENO} level_0 "    all"
    fnWriteLog ${LINENO} level_0 "    StandardStorage"
    fnWriteLog ${LINENO} level_0 "    StandardIAStorage"
    fnWriteLog ${LINENO} level_0 "    ReducedRedundancyStorage"   
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# load "all" storage types
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " load "all" storage types  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
if [[ "$storage_type" = "all" ]] 
	then 
		storage_type=$'StandardStorage\nStandardIAStorage\nReducedRedundancyStorage'
fi
#
###################################################
#
#
# parameter post-validation values
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " parameter post-validation values  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "values of input variables after validation  "
# 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile_param': ""$cli_profile_param" 
fnWriteLog ${LINENO} "value of variable 'timestamp_start': ""$timestamp_start" 
fnWriteLog ${LINENO} "value of variable 'timestamp_end': ""$timestamp_end" 
fnWriteLog ${LINENO} "value of variable 'timestamp_period': ""$timestamp_period" 
fnWriteLog ${LINENO} "value of variable 'storage_type': ""$storage_type" 
fnWriteLog ${LINENO} ""
#
###############################################################################
# 
#
# initialize the baseline variables
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " initialize the baseline variables  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
this_utility_acronym="s3s"
this_utility_filename_plug="s3size"
date_file="$(date +"%Y-%m-%d-%H%M%S")"
this_path="$(pwd)"
this_file="$(basename "$0")"
full_path="${this_path}"/"$this_file"
this_log_temp_file_full_path="$this_path"/"$this_utility_filename_plug"-log-temp.log 
this_user="$(whoami)"
count_tasks_this_file_begin="$(cat "$full_path" | grep -c "\-\-\- begin\: " )"
count_tasks_this_file_end="$(cat "$full_path" | grep -c "\-\-\- end\: " )"
count_tasks_this_file_increment_all="$(cat "$full_path" | grep -c "fnCounterIncrementTask" )"
count_tasks_this_file_increment=$((count_tasks_this_file_increment_all-3))
counter_tasks_this_file=0
#
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "baseline parameter values:" 
fnWriteLog ${LINENO} "value of variable 'this_utility_acronym': "$this_utility_acronym" " 
fnWriteLog ${LINENO} "value of variable 'this_utility_filename_plug': "$this_utility_filename_plug" " 
fnWriteLog ${LINENO} "value of variable 'date_file': "$date_file" " 
fnWriteLog ${LINENO} "value of variable 'this_path': "$this_path" " 
fnWriteLog ${LINENO} "value of variable 'this_file': "$this_file" " 
fnWriteLog ${LINENO} "value of variable 'full_path': "$full_path" " 
fnWriteLog ${LINENO} "value of variable 'this_log_temp_file_full_path': "$this_log_temp_file_full_path" " 
fnWriteLog ${LINENO} "value of variable 'this_user': "$this_user" " 
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_begin': "$count_tasks_this_file_begin" " 
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_end': "$count_tasks_this_file_end" " 
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_increment_all': "$count_tasks_this_file_increment_all" " 
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_increment': "$count_tasks_this_file_increment" " 
fnWriteLog ${LINENO} "value of variable 'counter_tasks_this_file': "$counter_tasks_this_file" " 
fnWriteLog ${LINENO} "" 

###################################################
#
# iniitialzie the temp log file  
# 
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " iniitialzie the temp log file  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
feed_write_log="$(echo "" > "$this_log_temp_file_full_path" 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
        feed_write_log="$(echo "$feed_write_log")"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                    
        # call the command / pipeline error function
        fnErrorPipeline
        #
        #
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
#
###################################################
#
#
# log the task counts  
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " log the task counts   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_begin': "$count_tasks_this_file_begin" "
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_end': "$count_tasks_this_file_end" "
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_increment': "$count_tasks_this_file_increment" "
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " build the menu and header text line and bars   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
text_header='AWS S3 Bucket Size Utility v'
count_script_version_length=${#script_version}
count_text_header_length=${#text_header}
count_text_block_length=$(( count_script_version_length + count_text_header_length ))
count_text_width_menu=104
count_text_width_header=83
count_text_side_length_menu=$(( (count_text_width_menu - count_text_block_length) / 2 ))
count_text_side_length_header=$(( (count_text_width_header - count_text_block_length) / 2 ))
count_text_bar_menu=$(( (count_text_side_length_menu * 2) + count_text_block_length + 2 ))
count_text_bar_header=$(( (count_text_side_length_header * 2) + count_text_block_length + 2 ))
# source and explanation for the following use of printf is here: https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
text_bar_menu_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_menu")  )"
text_bar_header_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_header")  )"
text_side_menu="$(printf '%0.s-' $(seq 1 "$count_text_side_length_menu")  )"
text_side_header="$(printf '%0.s-' $(seq 1 "$count_text_side_length_header")  )"
text_menu="$(echo "$text_side_menu"" ""$text_header""$script_version"" ""$text_side_menu")"
text_menu_bar="$(echo "$text_bar_menu_build")"
text_header="$(echo " ""$text_side_header"" ""$text_header""$script_version"" ""$text_side_header")"
text_header_bar="$(echo " ""$text_bar_header_build")"
#
###################################################
#
#
# check command line parameters 
# check for valid AWS CLI profile or for a profile driver file
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters    "
fnWriteLog ${LINENO} " check for valid AWS CLI profile or for a profile driver file   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the available AWS CLI profiles that match the -p parameter profile name "
count_cli_profile="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile_param")"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_cli_profile':"
fnWriteLog ${LINENO} "$count_cli_profile" 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile_param':"
fnWriteLog ${LINENO} "$cli_profile_param" 
fnWriteLog ${LINENO} ""
# set the file name
file_driver="$cli_profile_param"
# test for valid profile parameter 
# if no match, then display the error message and the available AWS CLI profiles 
if [[ "$count_cli_profile" -ne 1 ]] && [[ ! -f "$this_path"/"$file_driver" ]]
    then
		#
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid AWS CLI profile parameter: "$cli_profile_param" " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  No profile or profile-driver.txt file matches: -p "$cli_profile_param""
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  You can use a single profile for one account or a profile-driver.txt file"
        fnWriteLog ${LINENO} level_0 "  for multiple accounts"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Available AWS CLI profiles are:"
        cli_profile_available="$(cat /home/"$this_user"/.aws/config | grep "\[profile" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} level_0 "$cli_profile_available "
        fnWriteLog ${LINENO} level_0 ""
        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile profileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
     	#
fi
#
#
##########################################################################
#
#
# ---- begin: test for the profile driver file 
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " test for the profile driver file   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
# check the cli_profile_param to determine the type: single parameter or a driver file
# load the count_cli_profile variable if the parameter is a file
if [[ "$count_cli_profile" -eq 0 ]] && [[ -f "$this_path"/"$file_driver" ]]
    then
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "no valid profile name, the cli_profile_param is a valid file name  "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "using the file to drive multiple profiles for this run "
        fnWriteLog ${LINENO} "setting variable 'count_cli_profile' with a count of the file lines  "
        count_cli_profile="$(cat "$cli_profile_param" | wc -l )"
        #
		# check for command / pipeline error(s)
		if [ "$?" -ne 0 ]
		    then
		        #
		        # set the command/pipeline error line number
		        error_line_pipeline="$((${LINENO}-7))"
		        #
		        #
		        fnWriteLog ${LINENO} level_0 ""
		        fnWriteLog ${LINENO} level_0 "value of variable 'count_cli_profile':"
		        feed_write_log="$(echo "$count_cli_profile")"
		        fnWriteLog ${LINENO} level_0 "$feed_write_log"
		        fnWriteLog ${LINENO} level_0 ""
		        #                                                    
		        # call the command / pipeline error function
		        fnErrorPipeline
		        #
		        #
		fi # end check for command / pipeline error(s)
		#
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'count_cli_profile': "$count_cli_profile" " 
		fnWriteLog ${LINENO} ""
		#
        fnWriteLog ${LINENO} "setting variable 'cli_profile' with the file content  "
        cli_profile="$(cat "$cli_profile_param" )"
        #
		# check for command / pipeline error(s)
		if [ "$?" -ne 0 ]
		    then
		        #
		        # set the command/pipeline error line number
		        error_line_pipeline="$((${LINENO}-7))"
		        #
		        #
		        fnWriteLog ${LINENO} level_0 ""
		        fnWriteLog ${LINENO} level_0 "value of variable 'cli_profile':"
		        feed_write_log="$(echo "$cli_profile")"
		        fnWriteLog ${LINENO} level_0 "$feed_write_log"
		        fnWriteLog ${LINENO} level_0 ""
		        #                                                    
		        # call the command / pipeline error function
		        fnErrorPipeline
		        #
		        #
		fi # end check for command / pipeline error(s)
		#	
		# check the driver file for valid profiles
		while read cli_profile_file_check_line
		do
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'cli_profile_file_check_line':"
			fnWriteLog ${LINENO} "$cli_profile_file_check_line" 
			fnWriteLog ${LINENO} ""
			# strip trailing newlines
			cli_profile_file_check_line_strip="$(echo "$cli_profile_file_check_line" | tr -d '\n\r' )"
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'cli_profile_file_check_line_strip':"
			fnWriteLog ${LINENO} "$cli_profile_file_check_line_strip" 
			fnWriteLog ${LINENO} ""
			#
			# check the AWS CLI profile name to see if it exists on this system
			count_cli_profile_file_check="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile_file_check_line_strip")"
			# check for valid profile count
			if [[ "$count_cli_profile_file_check" -ne 1 ]] 
			    then
					#
			        clear
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  ERROR: The profile driver file contains an invalid "
			        fnWriteLog ${LINENO} level_0 "         AWS CLI profile name: "$cli_profile_file_check_line_strip" " 
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  Profile driver file name: "$cli_profile_param" " 
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  No AWS CLI profile on this system matches: "$cli_profile_file_check_line_strip""
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 ""			        
			        fnWriteLog ${LINENO} level_0 "  Available AWS CLI profiles on this system are:"
			        cli_profile_available="$(cat /home/"$this_user"/.aws/config | grep "\[profile" 2>&1)"
			        #
			        # check for command / pipeline error(s)
			        if [ "$?" -ne 0 ]
			            then
			                #
			                # set the command/pipeline error line number
			                error_line_pipeline="$((${LINENO}-7))"
			                #
			                # call the command / pipeline error function
			                fnErrorPipeline
			                #
			        #
			        fi
			        #
			        fnWriteLog ${LINENO} level_0 ""
			        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
			        fnWriteLog ${LINENO} level_0 "$feed_write_log"
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile MyProfileName "
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
			        fnWriteLog ${LINENO} level_0 ""
			     	#
			        fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "  Exiting the utility "
			        fnWriteLog ${LINENO} level_0 ""
				    fnWriteLog ${LINENO} level_0 ""
			        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
			        fnWriteLog ${LINENO} level_0 ""
				    # append the temp log onto the log file
				    fnWriteLogTempFile
				    # write the log variable to the log file
				    fnWriteLogFile
				    exit 1
			     	#
			fi # done check for valid driver file profile name line
			#
		done< <(echo "$cli_profile")
		#
	elif [[ "$count_cli_profile" -eq 1 ]] && [[ ! -f "$this_path"/"$file_driver" ]]
	    then
	        fnWriteLog ${LINENO} level_0 ""
	        fnWriteLog ${LINENO} level_0 "valid profile name, the cli_profile_param is not a valid file name  "
	        fnWriteLog ${LINENO} level_0 ""
	        fnWriteLog ${LINENO} level_0 "using the profile parameter to drive a single profile for this run "
	        cli_profile="$cli_profile_param"
fi # end check for cli_profile_param type
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile': " 
feed_write_log="$(echo "$cli_profile" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
#
#
fnWriteLog ${LINENO} "increment the task counter"
#
fnCounterIncrementTask
#
#
# ---- end: test for the profile driver file
#
#
###################################################
#
#
# set the task counts
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " set the task counts   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_cli_profile': " 
feed_write_log="$(echo "$count_cli_profile" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
counter_cli_profile="$count_cli_profile"
counter_cli_profile_task_display=0
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'counter_cli_profile': " 
feed_write_log="$(echo "$counter_cli_profile" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'counter_cli_profile_task_display': " 
feed_write_log="$(echo "$counter_cli_profile_task_display" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
# add the profile count to the task count
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "calculate the number of tasks for this job  "
#
# load this bash script into the varible 'tasks_code'
tasks_code="$(cat "$full_path")"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'tasks_code':"
        feed_write_log="$(echo "$tasks_code")"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                    
        # call the command / pipeline error function
        fnErrorPipeline
        #
        #
fi
#
#
# find the loop start line number
tasks_loop_line_start="$(echo "$tasks_code" | sed -n '/begin: read AWS CLI profiles/=' | sed -n '2{p;q}' )"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'tasks_loop_line_start': "$tasks_loop_line_start"  "
fnWriteLog ${LINENO} ""
#
# find the loop end line number
tasks_loop_line_end="$(echo "$tasks_code" | sed -n '/end: read AWS CLI profiles/=' | sed -n '2{p;q}' )"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'tasks_loop_line_end': "$tasks_loop_line_end"  "
fnWriteLog ${LINENO} ""
#
# count the loop tasks
count_tasks_loop="$(echo "$tasks_code" | sed $tasks_loop_line_start,$tasks_loop_line_end!d | grep -c "\-\-\- end\: "  )"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_tasks_loop': "$count_tasks_loop"  "
fnWriteLog ${LINENO} ""
#
# count the tasks in the entire script
count_tasks_this_file_all="$(echo "$tasks_code" | grep -c "\-\-\- end\: " )"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_all': "$count_tasks_this_file_all"  "
fnWriteLog ${LINENO} ""
#
# calculate the non-loop tasks
count_tasks_this_file_non_loop=$((count_tasks_this_file_all - count_tasks_loop))
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file_non_loop': "$count_tasks_this_file_non_loop"  "
fnWriteLog ${LINENO} ""
#
# calculate the total tasks based on the number of profiles 
if [[ "$count_cli_profile" -gt 1 ]]
	then 
		fnWriteLog ${LINENO} "more than one cli_profile, using a file"
		fnWriteLog ${LINENO} "count_tasks formula: ( count_tasks_this_file_non_loop + (count_cli_profile * count_tasks_loop) - (count_cli_profile - 1 ) ) "
		count_tasks_this_file=$((count_tasks_this_file_non_loop + (count_cli_profile * count_tasks_loop) - (count_cli_profile - 1 ) ))
	else
		fnWriteLog ${LINENO} "one cli_profile, using the cli_profile command-line parameter"
		fnWriteLog ${LINENO} "count_tasks formula: ( count_tasks_this_file_non_loop + (count_cli_profile * count_tasks_loop) ) "		
		count_tasks_this_file=$((count_tasks_this_file_non_loop + (count_cli_profile * count_tasks_loop) ))
fi
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_tasks_this_file': "$count_tasks_this_file"  "
fnWriteLog ${LINENO} ""
#
#
###################################################
#
#
# log the updated task count  
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " log the updated task count    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
fnWriteLog ${LINENO} "post 'add profile count' value of variable 'count_tasks_this_file': "$count_tasks_this_file" "
#
###################################################
#
#
# clear the console
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " clear the console   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
clear
# 
######################################################################################################################################################################
#
#
# Opening menu
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " Opening menu   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
#
######################################################################################################################################################################
#
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Write AWS S3 Bucket Size to JSON and CSV files   "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Number of AWS accounts to pull bucket sizes: "$count_cli_profile" "
fnWriteLog ${LINENO} level_0 ""
if [[ "$count_cli_profile" -gt 1 ]]
	then 
		fnWriteLog ${LINENO} level_0 "Driver file name: "$file_driver" "
		fnWriteLog ${LINENO} level_0 ""
fi
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "The AWS S3 bucket sizes will be written to JSON and CSV files"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 " >> Note: There is no undo for this operation << "
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS S3 Bucket Size utility"
fnWriteLog ${LINENO} level_0 "Run Utility Y/N Menu"
#
# Present a menu to allow the user to exit the utility and do the preliminary steps
#
# Menu code source: https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script
#
# Define the choices to present to the user, which will be
# presented line by line, prefixed by a sequential number
# (E.g., '1) copy', ...)
choices=( 'Run' 'Exit' )
#
# Present the choices.
# The user chooses by entering the *number* before the desired choice.
select choice in "${choices[@]}"; do
#   
    # If an invalid number was chosen, "$choice" will be empty.
    # Report an error and prompt again.
    [[ -n "$choice" ]] || { fnWriteLog ${LINENO} level_0 "Invalid choice." >&2; continue; }
    #
    # Examine the choice.
    # Note that it is the choice string itself, not its number
    # that is reported in "$choice".
    case "$choice" in
        Run)
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Running AWS Service Snapshot utility"
                fnWriteLog ${LINENO} level_0 ""
                # Set flag here, or call function, ...
            ;;
        Exit)
        #
        #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Exiting the utility..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                # delete the work files
                fnDeleteWorkFiles
                # append the temp log onto the log file
                fnWriteLogTempFile
                # write the log variable to the log file
                fnWriteLogFile
                exit 1
    esac
    #
    # Getting here means that a valid choice was made,
    # so break out of the select statement and continue below,
    # if desired.
    # Note that without an explicit break (or exit) statement, 
    # bash will continue to prompt.
    break
    #
    # end select - menu 
    # echo "at done"
done
#
##########################################################################
#
#      *********************  begin script *********************
#
##########################################################################
#
##########################################################################
#
#
# ---- begin: write the start timestamp to the log 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " write the start timestamp to the log   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
#
# display the header
#
fnHeader
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run start timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} ""  
#
#
#
#
fnWriteLog ${LINENO} "increment the task counter"
#
fnCounterIncrementTask
#
# ---- end: write the start timestamp to the log 
#
#
##########################################################################
#
#
# clear the console for the run 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " clear the console for the run  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
#
# display the header
#
fnHeader
#
#
##########################################################################
#
#
# pull the bucket sizes  
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " pull the bucket sizes  "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling the S3 bucket sizes from AWS for "$count_cli_profile" profiles"
fnWriteLog ${LINENO} ""
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "-------------------------------------- begin: read AWS CLI profiles --------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
while read -r cli_profile_line
do
	#
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	            
    fnWriteLog ${LINENO} "----------------------- loop head: read variable 'cli_profile' ------------------------  "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	            
    fnWriteLog ${LINENO} ""
    #
	#
    #
    # display the header    
    #
    fnHeader
    #
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'cli_profile_line':"
	fnWriteLog ${LINENO} "$cli_profile_line" 
	fnWriteLog ${LINENO} ""
	# strip trailing newlines
	cli_profile_line_strip="$(echo "$cli_profile_line" | tr -d '\n\r' )"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'cli_profile_line_strip':"
	fnWriteLog ${LINENO} "$cli_profile_line_strip" 
	fnWriteLog ${LINENO} "next log line"
	fnWriteLog ${LINENO} ""
    #
	fnWriteLog ${LINENO} level_0 ""
	fnWriteLog ${LINENO} level_0 "Setting up to pull bucket sizes for profile: "$cli_profile_line_strip" "
	fnWriteLog ${LINENO} level_0 ""
	#
	#
	###################################################
	#
	#
	# ---- begin: pull the AWS account number
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " pull the AWS account number  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "pulling AWS account"
	fnWriteLog ${LINENO} "command: aws sts get-caller-identity --profile ""$cli_profile_line_strip"" --output text --query 'Account'"
	aws_account="$(aws sts get-caller-identity --profile "$cli_profile_line_strip" --output text --query 'Account')"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
        then
            clear 
            # AWS API Error 
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "AWS error message: "
            fnWriteLog ${LINENO} level_0 "$aws_account"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            #
            # set the awserror line number
            error_line_aws="$((${LINENO}-15))"
            #
            # call the AWS error handler
            fnErrorAws
            #
    fi # end AWS API error check
    #
	#
	fnWriteLog ${LINENO} ""	
	fnWriteLog ${LINENO} "value of variable 'aws_account': "$aws_account" "
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#
	#
	# ---- end: pull the AWS account number
	#
	###################################################
	#
	#
	# ---- begin: pull the AWS account alias
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " pull the AWS account alias  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "pulling AWS account alias"
	aws_account_alias="$(aws iam list-account-aliases --profile "$cli_profile_line_strip" --output text --query 'AccountAliases' )"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
        then
            clear 
            # AWS API Error 
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "AWS error message: "
            fnWriteLog ${LINENO} level_0 "$aws_account_alias"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            #
            # set the awserror line number
            error_line_aws="$((${LINENO}-15))"
            #
            # call the AWS error handler
            fnErrorAws
            #
    fi # end AWS API error check
    #
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'aws_account_alias': "$aws_account_alias" "
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: pull the AWS account alias
	#
	###################################################
	#
	#
	# ---- begin: load the account dependent variables
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " load the account dependent variables  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 
	write_path="$this_path"/aws-"$aws_account"-"$this_utility_filename_plug"-"$date_file"
	write_path_s3_size="$write_path"/"$this_utility_filename_plug"-files
	this_path_temp="$write_path"/"$this_utility_acronym"-temp-"$date_file"
	this_log_file="aws-""$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-"$log_suffix".log 
	this_log_file_errors=aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-errors.log 
	this_log_file_full_path="$write_path"/"$this_log_file"
	this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
	this_summary_report="aws-""$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-summary-report.txt
	this_summary_report_full_path="$write_path"/"$this_summary_report"
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: load the account dependent variables
	#
	###################################################
	#
	#
	# ---- begin: load the file and path name variables
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " load the file and path name variables  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 
	fnWriteLog ${LINENO} "loading variabe 'write_file_raw'"
	write_file_raw="aws-""$aws_account"-"$date_file"-s3-bucket-size.json
	fnWriteLog ${LINENO} "value of variable 'write_file_raw': "$write_file_raw" "
	write_file_clean="$(echo "$write_file_raw" | tr "/%\\<>:" "_" )"
	fnWriteLog ${LINENO} "value of variable 'write_file_clean': "$write_file_clean" "
	write_file="$(echo "$write_file_clean")"
	write_file_full_path="$write_path_s3_size"/"$write_file"
	fnWriteLog ${LINENO} "value of variable 'write_file': "$write_file" "
	fnWriteLog ${LINENO} "value of variable 'write_file_full_path': "$write_file_full_path" "
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} "loading variable 'write_file_build'"
	write_file_build_raw="aws-""$aws_account"-"$date_file"-s3-bucket-size-build.json
	fnWriteLog ${LINENO} "value of variable 'write_file_build_raw': "$write_file_build_raw" "
	write_file_build_clean="$(echo "$write_file_build_raw" | tr "/%\\<>:" "_" )"
	fnWriteLog ${LINENO} "value of variable 'write_file_build_clean': "$write_file_build_clean" "
	write_file_build="$(echo "$write_file_build_clean")"
	write_file_build_full_path="$this_path_temp"/"$write_file_build"
	fnWriteLog ${LINENO} "value of variable 'write_file_build': "$write_file_build" "
	fnWriteLog ${LINENO} "value of variable 'write_file_build_full_path': "$write_file_build_full_path" "
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} "loading variable 'write_file_types_build'"
	write_file_types_build_raw="aws-""$aws_account"-"$date_file"-s3-bucket-size-types-build.json
	fnWriteLog ${LINENO} "value of variable 'write_file_types_build_raw': "$write_file_types_build_raw" "
	write_file_types_build_clean="$(echo "$write_file_types_build_raw" | tr "/%\\<>:" "_" )"
	fnWriteLog ${LINENO} "value of variable 'write_file_types_build_clean': "$write_file_types_build_clean" "
	write_file_types_build="$(echo "$write_file_types_build_clean")"
	write_file_types_build_full_path="$this_path_temp"/"$write_file_types_build"
	fnWriteLog ${LINENO} "value of variable 'write_file_types_build': "$write_file_types_build" "
	fnWriteLog ${LINENO} "value of variable 'write_file_types_build_full_path': "$write_file_types_build_full_path" "
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} "loading variable 'write_file_size'"
	write_file_size="/aws-""$aws_account"-"$date_file""-s3-bucket-size-B-MB-GB-TB.csv"
	write_file_size_full_path="$write_path_s3_size"/"$write_file_size"
	fnWriteLog ${LINENO} "value of variable 'write_file_size': "$write_file_size" "
	fnWriteLog ${LINENO} "value of variable 'write_file_size_full_path': "$write_file_size_full_path" "
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: load the file and path name variables
	#
	###################################################
	#
	#
	# ---- begin: create the directories
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " create the directories  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 	
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "creating write path directories "
	feed_write_log="$(mkdir -p "$write_path_s3_size" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "status of write path directories "
	feed_write_log="$(ls -ld */ "$this_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "creating temp path directory "
	feed_write_log="$(mkdir -p "$this_path_temp" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "status of temp path directories "
	feed_write_log="$(ls -ld */ "$this_path_temp" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: create the directories	
	#
	###############################################################################
	# 
	#
	# ---- begin: Initialize the log file
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " Initialize the log file  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 		
	if [[ "$logging" = "y" ]] ;
	    then
	        fnWriteLog ${LINENO} ""
	        fnWriteLog ${LINENO} "initializing the log file "
	        fnWriteLog ${LINENO} ""
	        echo "Log start" > "$this_log_file_full_path"
	        echo "" >> "$this_log_file_full_path"
	        echo "This log file name: "$this_log_file"" >> "$this_log_file_full_path"
	        echo "" >> "$this_log_file_full_path"
	        #
	        fnWriteLog ${LINENO} ""
	        fnWriteLog ${LINENO} "contents of file:'$this_log_file_full_path' "
	        feed_write_log="$(cat "$this_log_file_full_path"  2>&1)"
	        fnWriteLog ${LINENO} "$feed_write_log"
	        fnWriteLog ${LINENO} ""
	#
	fi
 	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#
	#
	# ---- end: Initialize the log file 	
	#
	###############################################################################
	# 
	#
	# ---- begin: Initialize the error log file
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " Initialize the error log file  "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 		
	echo "  Errors:" > "$this_log_file_errors_full_path"
	echo "" >> "$this_log_file_errors_full_path"
	#
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: Initialize the error log file 
	#
	#
	##########################################################################
	#
	#
	# ---- begin: display the log location 
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " display the log location   "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 			
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
	fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "Run log: "$this_log_file_full_path" " 
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
	fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "" 
	#
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: display the log location 
	#
	###################################################
	#
	#
	# ---- begin: initialize the files 
	#
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " initialize the files    "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 				
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "initializing build file with JSON opening : "{ \"AwsAccount\": \""$aws_account"\", \"AwsAccountAlias\": \""$aws_account_alias"\",\"UtilityRunTimestamp\": \""$date_file"\", \"Buckets\": [ " "
	fnWriteLog ${LINENO} ""	
	fnWriteLog ${LINENO} "initializing build file: "$write_file_build_full_path" "
	feed_write_log="$(echo "{ \"AwsAccount\": \""$aws_account"\", \"AwsAccountAlias\": \""$aws_account_alias"\",\"UtilityRunTimestamp\": \""$date_file"\", \"Buckets\": [ " > "$write_file_build_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} "initializing file: "$write_file_full_path" "
	feed_write_log="$(echo "" > "$write_file_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "initializing file: "$write_file_size_full_path" "
	feed_write_log="$(echo "" > "$write_file_size_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            feed_write_log="$(echo "$feed_write_log")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	# ---- end: initialize the files 
	#
	#
	###################################################
	#
	#
	# load the s3 bucket size JSON file
	#
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " load the s3 bucket size JSON file    "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 					
    # display the header    
    #
    fnHeader
    #
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_cli_profile_task_display" "$count_cli_profile"
    #
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "Creating file: "$write_file""
	#
	#
	fnWriteLog ${LINENO} level_0 ""
	fnWriteLog ${LINENO} level_0 "Pulling buckets for account: "$aws_account" "$aws_account_alias"  "
	fnWriteLog ${LINENO} level_0 ""
	fnWriteLog ${LINENO} "command: aws s3api list-buckets --query Buckets[].Name --profile "$cli_profile_line_strip" | tr -d \'\,\"][\'  "
	#
	bucket_list="$(aws s3api list-buckets --query "Buckets[].Name" --profile "$cli_profile_line_strip" | tr -d ',"][ ' | grep -v -e '^$')"
    #
    # check for errors from the AWS API  
    if [ "$?" -ne 0 ]
        then
            clear 
            # AWS API Error 
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "AWS error message: "
            fnWriteLog ${LINENO} level_0 "$bucket_list"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            #
            # set the awserror line number
            error_line_aws="$((${LINENO}-15))"
            #
            # call the AWS error handler
            fnErrorAws
            #
    fi # end AWS API error check
    #
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'bucket_list': " 
	feed_write_log="$(echo "$bucket_list" 2>&1)"
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#	
	fnWriteLog ${LINENO} "counting lines in bucket list"
	count_bucket_list="$(echo "$bucket_list" | wc -l )"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'count_bucket_list':"
	fnWriteLog ${LINENO} "$count_bucket_list" 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "loading variable 'counter_bucket_list' "
	counter_bucket_list="$count_bucket_list"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'counter_bucket_list':"
	fnWriteLog ${LINENO} "$counter_bucket_list" 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "loading variable 'counter_bucket_list_task_sub_display' "
	counter_bucket_list_task_sub_display=0
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'counter_bucket_list_task_sub_display':"
	fnWriteLog ${LINENO} "$counter_bucket_list_task_sub_display" 
	fnWriteLog ${LINENO} ""
	#
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "---------------------------------------- begin: read bucket names ----------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	while read bucket_name 
	do
		#
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	                
        fnWriteLog ${LINENO} "----------------------- loop head: read variable 'bucket_list' ------------------------  "
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	                
        fnWriteLog ${LINENO} ""
        #
		#
        #
        # display the header    
        #
        fnHeader
        #
        # display the task progress bar
        fnProgressBarTaskDisplay "$counter_cli_profile_task_display" "$count_cli_profile"
        #
        # display the sub task progress bar
        fnProgressBarTaskSubDisplay "$counter_bucket_list_task_sub_display" "$count_bucket_list"
        #
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "********************************************************"
		fnWriteLog ${LINENO} level_0 ""
		fnWriteLog ${LINENO} level_0 "Accounts remaining: "$counter_cli_profile" "
		fnWriteLog ${LINENO} level_0 ""
		fnWriteLog ${LINENO} level_0 "Pulling bucket sizes for account: "$aws_account" "$aws_account_alias" "
		fnWriteLog ${LINENO} level_0 ""
		fnWriteLog ${LINENO} level_0 "Buckets remaining for account "$aws_account" "$aws_account_alias": "$counter_bucket_list""
		fnWriteLog ${LINENO} level_0 ""
		fnWriteLog ${LINENO} level_0 "Pulling bucket size for bucket: "$bucket_name" "
		fnWriteLog ${LINENO} level_0 ""
		fnWriteLog ${LINENO} "********************************************************"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#
		###################################################
		#
		#
		# initialize the storage type build file 
		#
		#
		fnWriteLog ${LINENO} ""  
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} " load the s3 bucket size JSON file    "
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} ""  
		# 						
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "initializing the storage types build file with JSON: "{ \"BucketStorageTypes\": [ "  "
		fnWriteLog ${LINENO} ""	
		fnWriteLog ${LINENO} "initializing file: "$write_file_types_build_full_path" "
		feed_write_log="$(echo "{ \"BucketStorageTypes\": [ " > "$write_file_types_build_full_path")"
	    #
	    # check for command / pipeline error(s)
	    if [ "$?" -ne 0 ]
	        then
	            #
	            # set the command/pipeline error line number
	            error_line_pipeline="$((${LINENO}-7))"
	            #
	            #
	            fnWriteLog ${LINENO} level_0 ""
	            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
	            feed_write_log="$(echo "$feed_write_log")"
	            fnWriteLog ${LINENO} level_0 "$feed_write_log"
	            fnWriteLog ${LINENO} level_0 ""
	            #                                                    
	            # call the command / pipeline error function
	            fnErrorPipeline
	            #
	            #
	    fi
	    #
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		#
		# set the storage type counters
		count_storage_type="$(echo "$storage_type" | wc -l)"
		counter_storage_type=1 
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'count_storage_type':"
		fnWriteLog ${LINENO} "$count_storage_type" 
		fnWriteLog ${LINENO} ""	
		#
		# pull the bucket size for the storage type
		#
		# uses three types of S3 storage:
		# * StandardStorage
		# * StandardIAStorage
		# * ReducedRedundancyStorage
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "------------------------------------- begin get bucket storage sizes -------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "entering bucket size loop"
		fnWriteLog ${LINENO} ""		
		while read storage_type_line
		do
			#
	        #
	        fnWriteLog ${LINENO} ""
	        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        	        
	        fnWriteLog ${LINENO} "----------------------- loop head: read variable 'storage_type' -----------------------  "
	        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        	        
	        fnWriteLog ${LINENO} ""
	        #	
            #
	        # display the header    
	        #
	        fnHeader
	        #
	        # display the task progress bar
	        fnProgressBarTaskDisplay "$counter_cli_profile_task_display" "$count_cli_profile"
	        #
	        # display the sub task progress bar
	        fnProgressBarTaskSubDisplay "$counter_bucket_list_task_sub_display" "$count_bucket_list"
	        #
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "*****************************************************************************"
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} level_0 "Accounts remaining: "$counter_cli_profile" "
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} level_0 "Pulling bucket sizes for account: "$aws_account" "$aws_account_alias" "
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} level_0 "Buckets remaining for account "$aws_account" "$aws_account_alias": "$counter_bucket_list""
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} level_0 "Pulling bucket size for bucket: "$bucket_name" "
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} level_0 "Pulling bucket size for storage type: "$storage_type_line" "
			fnWriteLog ${LINENO} level_0 ""
			fnWriteLog ${LINENO} "*****************************************************************************"
			fnWriteLog ${LINENO} ""
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'storage_type_line':"
			fnWriteLog ${LINENO} "$storage_type_line" 
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'counter_storage_type':"
			fnWriteLog ${LINENO} "$counter_storage_type" 
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "pulling bucket size from AWS cloudwatch"	
			feed_write_log="command: aws cloudwatch get-metric-statistics --namespace AWS/S3 --start-time "$timestamp_start" --end-time "$timestamp_end" --period "$timestamp_period" --statistics Average --metric-name BucketSizeBytes --dimensions Name=BucketName,Value="$bucket_name" Name=StorageType,Value="$storage_type_line" --profile "$cli_profile_line_strip" "
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			region_specific=$(aws s3api get-bucket-location --bucket $bucket_name --profile "$cli_profile_line_strip"  | jq -r '.LocationConstraint')
			# region checker
			fnWriteLog "region: " ${region_specific} 
			if [ $region_specific == "null" ]; then
				bucket_size_json_results="$(aws cloudwatch get-metric-statistics --namespace AWS/S3 --start-time "$timestamp_start" --end-time "$timestamp_end" --period "$timestamp_period" --statistics Average --metric-name BucketSizeBytes --dimensions Name=BucketName,Value="$bucket_name" Name=StorageType,Value="$storage_type_line" --profile "$cli_profile_line_strip")"
			else
				bucket_size_json_results="$(aws cloudwatch get-metric-statistics --namespace AWS/S3 --start-time "$timestamp_start" --end-time "$timestamp_end" --period "$timestamp_period" --statistics Average --metric-name BucketSizeBytes --dimensions Name=BucketName,Value="$bucket_name" Name=StorageType,Value="$storage_type_line" --profile "$cli_profile_line_strip" --region "$region_specific")"
			fi
            #
            # check for errors from the AWS API  
            if [ "$?" -ne 0 ]
                then
                    clear 
                    # AWS API Error 
                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "AWS error message: "
                    fnWriteLog ${LINENO} level_0 "$bucket_size_json_results"
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                    #
                    # set the awserror line number
                    error_line_aws="$((${LINENO}-15))"
                    #
                    # call the AWS error handler
                    fnErrorAws
                    #
            fi # end AWS API error check
            #
			fnWriteLog ${LINENO} ""
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_json_results': " 
			feed_write_log="$(echo "$bucket_size_json_results" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#
			# set the bytes variable
			# add totals to the JSON
			#
			bucket_size_bytes="$(echo "$bucket_size_json_results" | jq '.Datapoints[].Average')"
			#
	        # check for jq error
	        if [ "$?" -ne 0 ]
	            then
	                # jq error 
	                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
	                fnWriteLog ${LINENO} level_0 ""
	                fnWriteLog ${LINENO} level_0 "jq error message: "
	                fnWriteLog ${LINENO} level_0 "$bucket_size_bytes"
	                fnWriteLog ${LINENO} level_0 ""
	                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
	                #
	                # set the jqerror line number
	                error_line_jq="$((${LINENO}-14))"
	                #
	                # call the jq error handler
	                fnErrorJq
	                #
	        fi # end jq error
	        #
			fnWriteLog ${LINENO} ""
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_bytes': " 
			feed_write_log="$(echo "$bucket_size_bytes" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			if [[ "$bucket_size_bytes" = "" ]]
				then
					fnWriteLog ${LINENO} ""
					fnWriteLog ${LINENO} "Bucket: "$bucket_name" has zero bytes for storage type: "$storage_type_line" "
					fnWriteLog ${LINENO} "setting variable 'bucket_size_bytes' to 0.00"
					bucket_size_bytes=0.00
					fnWriteLog ${LINENO} ""
					fnWriteLog ${LINENO} "value of variable 'bucket_size_bytes': " 
					feed_write_log="$(echo "$bucket_size_bytes" 2>&1)"
					fnWriteLog ${LINENO} "$feed_write_log"
					fnWriteLog ${LINENO} ""
			fi
			#
			# megabyte: 2^20 = 1,048,576 Bytes
			bucket_size_megabytes="$(echo "$bucket_size_bytes" | awk '{printf "%.2f\n", $1/1048576}')"
			#
			# gigabyte: 2^30 = 1,073,741,824 Bytes
			bucket_size_gigabytes="$(echo "$bucket_size_bytes" | awk '{printf "%.2f\n", $1/1073741824}')"
			#
			# terabyte = 2^40 = 1,099,511,627,776 Bytes
			bucket_size_terabytes="$(echo "$bucket_size_bytes" | awk '{printf "%.2f\n", $1/1099511627776}')"
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_megabytes':"
			fnWriteLog ${LINENO} "${bucket_size_megabytes}" 
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_gigabytes':"
			fnWriteLog ${LINENO} "${bucket_size_gigabytes}" 
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_terabytes':"
			fnWriteLog ${LINENO} "${bucket_size_terabytes}" 
			fnWriteLog ${LINENO} ""
			#
			# add size totals to the JSON
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'counter_storage_type':"
			fnWriteLog ${LINENO} "$counter_storage_type" 
			fnWriteLog ${LINENO} ""		
			fnWriteLog ${LINENO} ""
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_json_results': " 
			feed_write_log="$(echo "$bucket_size_json_results" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#
			# load the feed 
			bucket_size_feed="$(echo "$bucket_size_json_results")"
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_feed': " 
			feed_write_log="$(echo "$bucket_size_feed" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'storage_type_line': " 
			feed_write_log="$(echo "$storage_type_line" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#
			# add the bucket sizes
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "adding the bucket sizes to the JSON" 	
			fnWriteLog ${LINENO} "full command echo "	
			feed_write_log="command: echo  "$bucket_size_feed" | jq --arg storage_type_line_jq "$storage_type_line" --argjson bucket_size_bytes_jq $bucket_size_bytes --argjson bucket_size_megabytes_jq $bucket_size_megabytes --argjson bucket_size_gigabytes_jq $bucket_size_gigabytes --argjson bucket_size_terabytes_jq $bucket_size_terabytes '{StorageType: $storage_type_line_jq, BucketSizeBytes: $bucket_size_bytes_jq, BucketSizeMegabytes: $bucket_size_megabytes_jq, BucketSizeGigabytes: $bucket_size_gigabytes_jq, BucketSizeTerabytes: $bucket_size_terabytes_jq } + .'"			
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			bucket_size_json_edit_01="$(echo "$bucket_size_feed" | jq --arg storage_type_line_jq "$storage_type_line" --argjson bucket_size_bytes_jq $bucket_size_bytes --argjson bucket_size_megabytes_jq $bucket_size_megabytes --argjson bucket_size_gigabytes_jq $bucket_size_gigabytes --argjson bucket_size_terabytes_jq $bucket_size_terabytes '{StorageType: $storage_type_line_jq, BucketSizeBytes: $bucket_size_bytes_jq, BucketSizeMegabytes: $bucket_size_megabytes_jq, BucketSizeGigabytes: $bucket_size_gigabytes_jq, BucketSizeTerabytes: $bucket_size_terabytes_jq } + .' )"  
			#
	        # check for jq error
	        if [ "$?" -ne 0 ]
	            then
	                # jq error 
	                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
	                fnWriteLog ${LINENO} level_0 ""
	                fnWriteLog ${LINENO} level_0 "jq error message: "
	                fnWriteLog ${LINENO} level_0 "$bucket_size_json_edit_01"
	                fnWriteLog ${LINENO} level_0 ""
	                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
	                #
	                # set the jqerror line number
	                error_line_jq="$((${LINENO}-14))"
	                #
	                # call the jq error handler
	                fnErrorJq
	                #
	        fi # end jq error
	        #
			#
			fnWriteLog ${LINENO} ""
			#
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "value of variable 'bucket_size_json_edit_01': " 
			feed_write_log="$(echo "$bucket_size_json_edit_01" 2>&1)"
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#	
			# write the bucket size to the build file
			feed_write_log="$(echo "$bucket_size_json_edit_01" >> "$write_file_types_build_full_path" 2>&1)"
		    #
		    # check for command / pipeline error(s)
		    if [ "$?" -ne 0 ]
		        then
		            #
		            # set the command/pipeline error line number
		            error_line_pipeline="$((${LINENO}-7))"
		            #
		            #
		            fnWriteLog ${LINENO} level_0 ""
		            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
		            feed_write_log="$(echo "$feed_write_log")"
		            fnWriteLog ${LINENO} level_0 "$feed_write_log"
		            fnWriteLog ${LINENO} level_0 ""
		            #                                                    
		            # call the command / pipeline error function
		            fnErrorPipeline
		            #
		            #
		    fi
		    #
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			#
			# test for last storage type, add comma if not done
			if [[ "$counter_storage_type" < "$count_storage_type" ]]
				then 
					fnWriteLog ${LINENO} ""
					fnWriteLog ${LINENO} "not done with storage types"
					fnWriteLog ${LINENO} "adding a trailing comma for this JSON object  "
					fnWriteLog ${LINENO} ""				
					feed_write_log="$(echo "," >> "$write_file_types_build_full_path" 2>&1)"
				    #
				    # check for command / pipeline error(s)
				    if [ "$?" -ne 0 ]
				        then
				            #
				            # set the command/pipeline error line number
				            error_line_pipeline="$((${LINENO}-7))"
				            #
				            #
				            fnWriteLog ${LINENO} level_0 ""
				            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
				            feed_write_log="$(echo "$feed_write_log")"
				            fnWriteLog ${LINENO} level_0 "$feed_write_log"
				            fnWriteLog ${LINENO} level_0 ""
				            #                                                    
				            # call the command / pipeline error function
				            fnErrorPipeline
				            #
				            #
				    fi
				    #
					fnWriteLog ${LINENO} "$feed_write_log"
					fnWriteLog ${LINENO} ""
					#
				elif [[ "$counter_storage_type" = "$count_storage_type" ]]
					then
					# done with storage types, close out the results array and the BucketStorageTypes object
					fnWriteLog ${LINENO} ""
					fnWriteLog ${LINENO} "done with storage types"
					fnWriteLog ${LINENO} "closing the storage types build file with JSON: "] }"  "
					fnWriteLog ${LINENO} ""	
					feed_write_log="$(echo "] }" >> "$write_file_types_build_full_path" 2>&1)"
				    #
				    # check for command / pipeline error(s)
				    if [ "$?" -ne 0 ]
				        then
				            #
				            # set the command/pipeline error line number
				            error_line_pipeline="$((${LINENO}-7))"
				            #
				            #
				            fnWriteLog ${LINENO} level_0 ""
				            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
				            feed_write_log="$(echo "$feed_write_log")"
				            fnWriteLog ${LINENO} level_0 "$feed_write_log"
				            fnWriteLog ${LINENO} level_0 ""
				            #                                                    
				            # call the command / pipeline error function
				            fnErrorPipeline
				            #
				            #
				    fi
				    #
					fnWriteLog ${LINENO} "$feed_write_log"
					fnWriteLog ${LINENO} ""
					#
			fi # end test for storage type count 
			#
			# show the contents of the build file
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "contents of file: "$write_file_types_build_full_path": " 
			feed_write_log="$(cat "$write_file_types_build_full_path" 2>&1)"
		    #
		    # check for command / pipeline error(s)
		    if [ "$?" -ne 0 ]
		        then
		            #
		            # set the command/pipeline error line number
		            error_line_pipeline="$((${LINENO}-7))"
		            #
		            #
		            fnWriteLog ${LINENO} level_0 ""
		            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_types_build_full_path":"
		            feed_write_log="$(cat "$write_file_types_build_full_path")"
		            fnWriteLog ${LINENO} level_0 "$feed_write_log"
		            fnWriteLog ${LINENO} level_0 ""
		            #                                                    
		            # call the command / pipeline error function
		            fnErrorPipeline
		            #
		            #
		    fi
		    #
			fnWriteLog ${LINENO} "$feed_write_log"
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} ""
			#	
			#
			fnWriteLog ${LINENO} "incrementing the storage type counter: 'counter_storage_type'"
			counter_storage_type=$(($counter_storage_type + 1))
			fnWriteLog ${LINENO} ""
			fnWriteLog ${LINENO} "post-increment value of variable 'counter_storage_type':"
			fnWriteLog ${LINENO} "$counter_storage_type" 
			fnWriteLog ${LINENO} ""
			#
		    # write out the temp log and empty the log variable
		    fnWriteLogTempFile
	        #
	        #
	        fnWriteLog ${LINENO} ""
	        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        
	        fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'storage_type' -----------------------  "
	        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        	        
	        fnWriteLog ${LINENO} ""
	        #
	        #
		done< <(echo "$storage_type")
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "done with storage type loop"
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "------------------------------------* end: get bucket storage sizes --------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#
		#
		###################################################
		#
		#
		# add the totals and the bucket name to the JSON
		#
		fnWriteLog ${LINENO} ""  
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} " add the totals and the bucket name to the JSON    "
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} ""  
		# 						
		# load the feed raw
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "loading the variable 'bucket_name_feed_raw': "
		bucket_name_feed_raw="$(cat "$write_file_types_build_full_path" 2>&1)"
	    #
	    # check for command / pipeline error(s)
	    if [ "$?" -ne 0 ]
	        then
	            #
	            # set the command/pipeline error line number
	            error_line_pipeline="$((${LINENO}-7))"
	            #
	            #
	            fnWriteLog ${LINENO} level_0 ""
	            fnWriteLog ${LINENO} level_0 "value of variable 'bucket_name_feed_raw':"
	            feed_write_log="$(echo "$bucket_name_feed_raw")"
	            fnWriteLog ${LINENO} level_0 "$feed_write_log"
	            fnWriteLog ${LINENO} level_0 ""
	            #                                                    
	            # call the command / pipeline error function
	            fnErrorPipeline
	            #
	            #
	    fi
	    #
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'bucket_name_feed_raw': " 
		feed_write_log="$(echo "$bucket_name_feed_raw" 2>&1)"
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		#
		# load the feed 
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "loading the variable 'bucket_name_feed': "
		fnWriteLog ${LINENO} "piped through jq to prettify and format"	
		fnWriteLog ${LINENO} ""
		bucket_name_feed="$(echo "$bucket_name_feed_raw" | jq . 2>&1)"
		#
        # check for jq error
        if [ "$?" -ne 0 ]
            then
                # jq error 
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "jq error message: "
                fnWriteLog ${LINENO} level_0 "$bucket_name_feed"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                #
                # set the jqerror line number
                error_line_jq="$((${LINENO}-14))"
                #
                # call the jq error handler
                fnErrorJq
                #
        fi # end jq error
        #
		#
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'bucket_name_feed': " 
		feed_write_log="$(echo "$bucket_name_feed" 2>&1)"
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		#
		bucket_size_total_bytes="$(echo "$bucket_name_feed" | jq '.BucketStorageTypes[].BucketSizeBytes' | awk 'BEGIN {sum=0} {for(i=1;i<=NF;i++) sum+=$i} END {print sum}' 2>&1)"
		bucket_size_total_megabytes="$(echo "$bucket_name_feed" | jq '.BucketStorageTypes[].BucketSizeMegabytes' | awk 'BEGIN {sum=0} {for(i=1;i<=NF;i++) sum+=$i} END {print sum}' 2>&1)"
		bucket_size_total_gigabytes="$(echo "$bucket_name_feed" | jq '.BucketStorageTypes[].BucketSizeGigabytes' | awk 'BEGIN {sum=0} {for(i=1;i<=NF;i++) sum+=$i} END {print sum}' 2>&1)"
		bucket_size_total_terabytes="$(echo "$bucket_name_feed" | jq '.BucketStorageTypes[].BucketSizeTerabytes' | awk 'BEGIN {sum=0} {for(i=1;i<=NF;i++) sum+=$i} END {print sum}' 2>&1)"
		#
		#	
		fnWriteLog ${LINENO} "adding totals to JSON "
		fnWriteLog ${LINENO} "command: echo '"{$ bucket_name_feed"}' | jq --argjson bucket_size_total_bytes_jq "$bucket_size_total_bytes" --argjson bucket_size_total_megabytes_jq "$bucket_size_total_megabytes" --argjson bucket_size_total_gigabytes_jq "$bucket_size_total_gigabytes" --argjson bucket_size_total_terabytes_jq "$bucket_size_total_terabytes" '{BucketSizeTotalBytes: $bucket_size_total_bytes_jq, BucketSizeTotalMegabytes: $bucket_size_total_megabytes_jq, BucketSizeTotalGigabytes: $bucket_size_total_gigabytes_jq, BucketSizeTotalTerabytes: $bucket_size_total_terabytes_jq} + .'"
		fnWriteLog ${LINENO} ""
		#
		bucket_size_json_edit_02="$(echo "${bucket_name_feed}" | jq  --argjson bucket_size_total_bytes_jq "$bucket_size_total_bytes" --argjson bucket_size_total_megabytes_jq "$bucket_size_total_megabytes" --argjson bucket_size_total_gigabytes_jq "$bucket_size_total_gigabytes" --argjson bucket_size_total_terabytes_jq "$bucket_size_total_terabytes" '{BucketSizeTotalBytes: $bucket_size_total_bytes_jq, BucketSizeTotalMegabytes: $bucket_size_total_megabytes_jq, BucketSizeTotalGigabytes: $bucket_size_total_gigabytes_jq, BucketSizeTotalTerabytes: $bucket_size_total_terabytes_jq} + .'	2>&1)"
		#
        # check for jq error
        if [ "$?" -ne 0 ]
            then
                # jq error 
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "jq error message: "
                fnWriteLog ${LINENO} level_0 "$bucket_size_json_edit_02"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                #
                # set the jqerror line number
                error_line_jq="$((${LINENO}-14))"
                #
                # call the jq error handler
                fnErrorJq
                #
        fi # end jq error
        #
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'bucket_size_json_edit_02': " 
		feed_write_log="$(echo "$bucket_size_json_edit_02" 2>&1)"
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		#	
		fnWriteLog ${LINENO} "adding bucket name to JSON "
		fnWriteLog ${LINENO} "command: echo '"{$ bucket_size_json_edit_02"}' | jq --arg bucket_name_jq "$bucket_name"  '{BucketName: $bucket_name_jq} + .'"
		fnWriteLog ${LINENO} ""
		#
		bucket_size_json_edit_03="$(echo "${bucket_size_json_edit_02}" | jq --arg bucket_name_jq "$bucket_name" '{BucketName: $bucket_name_jq} + .' 2>&1)"
		#
        # check for jq error
        if [ "$?" -ne 0 ]
            then
                # jq error 
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "jq error message: "
                fnWriteLog ${LINENO} level_0 "$bucket_size_json_edit_03"
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                #
                # set the jqerror line number
                error_line_jq="$((${LINENO}-14))"
                #
                # call the jq error handler
                fnErrorJq
                #
        fi # end jq error
        #
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'bucket_size_json_edit_03': " 
		feed_write_log="$(echo "$bucket_size_json_edit_03" 2>&1)"
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		#	
		fnWriteLog ${LINENO} "adding variable 'bucket_size_json_edit_03' to file "$write_file_build_full_path" "
		feed_write_log="$(echo "$bucket_size_json_edit_03" >> "$write_file_build_full_path" 2>&1)" 
	    #
	    # check for command / pipeline error(s)
	    if [ "$?" -ne 0 ]
	        then
	            #
	            # set the command/pipeline error line number
	            error_line_pipeline="$((${LINENO}-7))"
	            #
	            #
	            fnWriteLog ${LINENO} level_0 ""
	            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
	            feed_write_log="$(cat "$write_file_build_full_path")"
	            fnWriteLog ${LINENO} level_0 "$feed_write_log"
	            fnWriteLog ${LINENO} level_0 ""
	            #                                                    
	            # call the command / pipeline error function
	            fnErrorPipeline
	            #
	            #
	    fi
	    #
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#		
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "decrementing variable: 'counter_bucket_list' "
		counter_bucket_list=$((counter_bucket_list - 1))
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "value of variable 'counter_bucket_list':"
		fnWriteLog ${LINENO} "$counter_bucket_list" 
		fnWriteLog ${LINENO} ""
		if [[ "$counter_bucket_list" -gt 0 ]] 
			then
				fnWriteLog ${LINENO} ""
				fnWriteLog ${LINENO} "not the first JSON object in this build "
				fnWriteLog ${LINENO} "adding trailing comma for this JSON object"
				feed_write_log="$(echo "," >> "$write_file_build_full_path" 2>&1)" 
			    #
			    # check for command / pipeline error(s)
			    if [ "$?" -ne 0 ]
			        then
			            #
			            # set the command/pipeline error line number
			            error_line_pipeline="$((${LINENO}-7))"
			            #
			            #
			            fnWriteLog ${LINENO} level_0 ""
			            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
			            feed_write_log="$(cat "$write_file_build_full_path")"
			            fnWriteLog ${LINENO} level_0 "$feed_write_log"
			            fnWriteLog ${LINENO} level_0 ""
			            #                                                    
			            # call the command / pipeline error function
			            fnErrorPipeline
			            #
			            #
			    fi
			    #
				fnWriteLog ${LINENO} "$feed_write_log"
				fnWriteLog ${LINENO} ""
				#	
		fi
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "contents of file: "$write_file_build_full_path": " 
		feed_write_log="$(cat "$write_file_build_full_path" 2>&1)"
	    #
	    # check for command / pipeline error(s)
	    if [ "$?" -ne 0 ]
	        then
	            #
	            # set the command/pipeline error line number
	            error_line_pipeline="$((${LINENO}-7))"
	            #
	            #
	            fnWriteLog ${LINENO} level_0 ""
	            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
	            feed_write_log="$(cat "$write_file_build_full_path")"
	            fnWriteLog ${LINENO} level_0 "$feed_write_log"
	            fnWriteLog ${LINENO} level_0 ""
	            #                                                    
	            # call the command / pipeline error function
	            fnErrorPipeline
	            #
	            #
	    fi
	    #
		fnWriteLog ${LINENO} "$feed_write_log"
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} ""
		#	
		#
		fnWriteLog ${LINENO} ""
		fnWriteLog ${LINENO} "increment the variable 'counter_bucket_list_task_sub_display' "
        counter_bucket_list_task_sub_display=$((counter_bucket_list_task_sub_display + 1))
		fnWriteLog ${LINENO} "post-increment value of variable 'counter_bucket_list_task_sub_display' "
		fnWriteLog ${LINENO} "$counter_bucket_list_task_sub_display"		
		fnWriteLog ${LINENO} ""       
		#
	    # write out the temp log and empty the log variable
	    fnWriteLogTempFile
        #
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	                
        fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'bucket_list' ------------------------  "
        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	                
        fnWriteLog ${LINENO} ""
        #
        #
	done< <(echo "$bucket_list")
	#
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------- end: read bucket names -----------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "done with bucket list loop"
	fnWriteLog ${LINENO} ""
	#
	###################################################
	#
	#
	# add the closing '] }' to the JSON file
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " add the closing '] }' to the JSON file    "
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	# 						
	fnWriteLog ${LINENO} "adding closing '] }' to file"
	feed_write_log="$(echo "] }" >> "$write_file_build_full_path" 2>&1)" 
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
            feed_write_log="$(cat "$write_file_build_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#	
	fnWriteLog ${LINENO} "" 
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "final contents of file: "$write_file_build_full_path": "  
	feed_write_log="$(cat "$write_file_build_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
            feed_write_log="$(cat "$write_file_build_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#	
	fnWriteLog ${LINENO} "" 
	fnWriteLog ${LINENO} "pipe results through jq to prettify" 
	feed_write_log="$(cat "$write_file_build_full_path" | jq . > "$write_file_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_build_full_path":"
            feed_write_log="$(cat "$write_file_build_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "contents of file: "$write_file_full_path": "
	feed_write_log="$(cat "$write_file_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_full_path":"
            feed_write_log="$(cat "$write_file_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	#
	###################################################
	#
	#
	# load the s3 bucket sizes B MB GB TB file
	#
	#
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "------------------------------------ begin: write the CSV sizes file -------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "Creating file: "$write_file_size""
	#
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "pulling the bucket name and sizes"
	bucket_size_name_bytes="$(cat "$write_file_full_path" | jq -c '.Buckets[] | {BucketName, BucketSizeTotalBytes, BucketSizeTotalMegabytes, BucketSizeTotalGigabytes, BucketSizeTotalTerabytes}' | jq -r '[.BucketName, .BucketSizeTotalBytes, .BucketSizeTotalMegabytes, .BucketSizeTotalGigabytes, .BucketSizeTotalTerabytes] | @csv' | tr -d '"' )"
	#
    # check for jq error
    if [ "$?" -ne 0 ]
        then
            # jq error 
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "jq error message: "
            fnWriteLog ${LINENO} level_0 "$bucket_size_bytes"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            #
            # set the jqerror line number
            error_line_jq="$((${LINENO}-14))"
            #
            # call the jq error handler
            fnErrorJq
            #
    fi # end jq error
    #
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'bucket_size_name_bytes':"
	fnWriteLog ${LINENO} "$bucket_size_name_bytes" 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "loading header line in file: "$write_file_size_full_path" "
	fnWriteLog ${LINENO} "loading variable: 'bucket_size_B_MB_GB_TB_build'"
	bucket_size_B_MB_GB_TB_header="bucket_name"','"bytes"','"megabytes"','"gigabytes"','"terabytes"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'bucket_size_B_MB_GB_TB_header':"
	fnWriteLog ${LINENO} "$bucket_size_B_MB_GB_TB_header" 
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "writing values to file: "$write_file_size_full_path""
	feed_write_log="$(echo "$bucket_size_B_MB_GB_TB_header" > "$write_file_size_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_size_full_path":"
            feed_write_log="$(cat "$write_file_size_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "contents of file: "$write_file_size_full_path":"
	feed_write_log="$(cat "$write_file_size_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_size_full_path":"
            feed_write_log="$(cat "$write_file_size_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "writing values to file: "$write_file_size_full_path""
	feed_write_log="$(echo "$bucket_size_name_bytes" >> "$write_file_size_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_size_full_path":"
            feed_write_log="$(cat "$write_file_size_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "contents of file: "$write_file_size_full_path":"
	feed_write_log="$(cat "$write_file_size_full_path" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$write_file_size_full_path":"
            feed_write_log="$(cat "$write_file_size_full_path")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
	fnWriteLog ${LINENO} "$feed_write_log"
	fnWriteLog ${LINENO} ""
	#
	#
	#
	fnWriteLog ${LINENO} "increment the task counter"
	#
	fnCounterIncrementTask
	#	
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "------------------------------------- end: write the CSV sizes file --------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	#
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "decrementing variable: 'counter_cli_profile' "
	counter_cli_profile=$((counter_cli_profile - 1))
	fnWriteLog ${LINENO} ""
	fnWriteLog ${LINENO} "value of variable 'counter_cli_profile':"
	fnWriteLog ${LINENO} "$counter_cli_profile" 
	fnWriteLog ${LINENO} ""
	#
	#
    #
	#
	fnWriteLog ${LINENO} "increment the cli_profile task display counter"
	counter_cli_profile_task_display=$((counter_cli_profile_task_display + 1))
	#
    # write out the temp log and empty the log variable
    fnWriteLogTempFile
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        
    fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'cli_profile' ------------------------  "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------  "	        
    fnWriteLog ${LINENO} ""
    #   
    #
    #
done< <(echo "$cli_profile")
#
#
#
fnWriteLog ${LINENO} "increment the task counter"
#
fnCounterIncrementTask
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------------------------- end: read AWS CLI profiles ---------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
#
#
# display the header    
#
fnHeader
#
# display the task progress bar
fnProgressBarTaskDisplay "$counter_cli_profile_task_display" "$count_cli_profile"
#
# display the sub task progress bar
fnProgressBarTaskSubDisplay "$counter_bucket_list_task_sub_display" "$count_bucket_list"
#
#
##########################################################################
#
#
# delete the work files 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------- begin: delete work files ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
fnDeleteWorkFiles
#
fnWriteLog ${LINENO} ""  
#
#
fnWriteLog ${LINENO} "increment the task counter"
#
fnCounterIncrementTask
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- end: delete work files -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# display the job complete message 
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the job complete message    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 						
# display the header    
#
fnHeader
#
# display the task progress bar
fnProgressBarTaskDisplay "$counter_cli_profile_task_display" "$count_cli_profile"
#
# display the sub task progress bar
fnProgressBarTaskSubDisplay "$counter_bucket_list_task_sub_display" "$count_bucket_list"
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "***********************************************"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Job Complete"
fnWriteLog ${LINENO} level_0 "results are here: "
fnWriteLog ${LINENO} level_0 "  "$this_path""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "***********************************************"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
#
##########################################################################
#
#
# write the stop timestamp to the log 
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " write the stop timestamp to the log     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 						
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run end timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
#
##########################################################################
#
#
# write the log file 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " write the log file      "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 						
if [[ "$logging" = "y" ]] 
    then 
		fnWriteLog ${LINENO} "" 
		fnWriteLog ${LINENO} "logging = y"
		fnWriteLog ${LINENO} "writing the logs"     	
        # append the temp log onto the log file
        fnWriteLogTempFile
        # write the log variable to the log file
        fnWriteLogFile
    else 
		fnWriteLog ${LINENO} "" 
		fnWriteLog ${LINENO} "logging != y"
		fnWriteLog ${LINENO} "deleting the temp log file"
        # delete the temp log file
        rm -f "$this_log_temp_file_full_path"        
fi
#
#
##########################################################################
#
#
# exit with success 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " exit with success     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
# 						
exit 0
#
#
#
##########################################
# 
# end shell script 
#
##########################################

