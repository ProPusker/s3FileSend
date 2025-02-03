
Overview
This PowerShell script is designed to automate the process of uploading files from local directories or network shares to an Amazon S3 bucket. It reads configuration details from one or more XML files, processes the specified commands, and uploads files based on the criteria defined in the XML. The script also supports moving files after successful uploads and includes robust logging and error handling.



**Features**
1. **XML Configuration**: The script reads configuration details from XML files, allowing for flexible and dynamic setup.
2. **File Upload**: Uploads files from specified source folders to an S3 bucket.
3. **File Filtering**: Filters files based on file format and age (e.g., files modified within the last `n` days).
4. **File Movement**: Optionally moves files after successful uploads.
5. **Logging**: Detailed logging with timestamps, script line numbers, and log levels (INFO, WARNING, ERROR).
6. **Error Handling**: Retries failed uploads up to 10 times with a delay between attempts.
7. **Modular Design**: Functions are modular, making the script easy to maintain and extend.
8. **Multiple Input Files**: Processes all `.xml` files in the script's directory.


 **Prerequisites
1. **PowerShell Version**: Requires PowerShell 5.1 or later.
2. **AWS Tools for PowerShell**: Ensure the AWS Tools for PowerShell module is installed. You can install it using:
   ```powershell
   Install-Module -Name AWSPowerShell -Force -Scope CurrentUser
   ```
3. **AWS Credentials**: Valid AWS access key ID and secret access key with permissions to upload files to the specified S3 bucket.
4. **Input XML Files**: One or more XML files defining the source folders, file formats, S3 bucket details, and other parameters.


**XML Parameters**
- **SourceFolder**: The local or network folder where the files are located.
- **FileFormat**: The file format to filter (e.g., `*.zip`, `*.csv`).
- **Age**: The maximum age of files in days (e.g., files modified within the last `2` days).
- **S3RegionEndpoint**: The AWS region where the S3 bucket is located (e.g., `us-west-2`).
- **S3BucketName**: The name of the S3 bucket.
- **S3AccessKeyID**: The AWS access key ID for authentication.
- **S3SecretAccessKey**: The AWS secret access key (base64 encoded) for authentication.
- **DestinationFolder**: The folder path in the S3 bucket where files will be uploaded.
- **Move**: If set to `true`, files will be deleted from the source folder after successful upload.


**Script Workflow**
1. **Initialization**:
   - The script initializes logging and sets up the log file.
   - Logs script metadata (script name, version, PowerShell version, computer name, and user).

2. **Input File Processing**:
   - The script searches for all `.xml` files in the script's directory.
   - For each XML file, it reads the configuration and processes the commands.

3. **File Upload**:
   - For each command, the script:
     - Filters files in the source folder based on file format and age.
     - Authenticates with AWS using the provided credentials.
     - Uploads files to the specified S3 bucket.
     - Optionally moves files after successful uploads.

4. **Error Handling**:
   - If an upload fails, the script retries up to 10 times with a delay between attempts.
   - Errors and warnings are logged with detailed information.

5. **Logging**:
   - All operations are logged with timestamps, script line numbers, and log levels.
   - Logs are saved to a file in the script's directory.

6. **Completion**:
   - The script logs the total execution time and the number of warnings (if any).
   - Exits with a status code of `0` for success or `1` for failure.

---

**Script Functions**
**1. Write-NoPrefixLog**
- **Purpose**: Writes a log message without a prefix to the log file.
- **Parameters**:
  - `Message`: The log message to write.

**2. Write-Log**
- **Purpose**: Writes a log message with a timestamp, script line number, and log level.
- **Parameters**:
  - `Message`: The log message to write.

**3. Init-LogFile**
- **Purpose**: Initializes the log file and logs script metadata.
- **Behavior**:
  - Creates the log file if it doesn't exist.
  - Rotates logs if the file size exceeds the limit.

**4. Decode64**
- **Purpose**: Decodes a base64-encoded string (used for decoding the AWS secret access key).
- **Parameters**:
  - `EncodedPassword`: The base64-encoded string to decode.

**5. S3-SafeUpload**
- **Purpose**: Uploads a file to an S3 bucket with retries on failure.
- **Parameters**:
  - `BucketName`: The name of the S3 bucket.
  - `FileName`: The full path of the file to upload.
  - `Destination`: The destination path in the S3 bucket.
  - `StorageClass`: The S3 storage class (e.g., `STANDARD`).

**6. Process-Command**
- **Purpose**: Processes a single command from the XML file.
- **Parameters**:
  - `Command`: The command object containing source folder, file format, S3 details, etc.

---

 **Usage**
1. **Prepare Input XML Files**:
   - Create one or more XML files with the required configuration (see [Input XML File Format](#input-xml-file-format)).

2. **Run the Script**:
   - Place the script and XML files in the same directory.
   - Run the script in PowerShell:
     ```powershell
     .\S3FileUploadUtility.ps1
     ```

3. **Review Logs**:
   - Logs are saved to a file named `S3FileUploadUtility.txt` in the script's directory.



## **Troubleshooting**
1. **No Files Found**:
   - Ensure the `SourceFolder` and `FileFormat` in the XML file are correct.
   - Verify that files matching the criteria exist in the source folder.

2. **AWS Authentication Errors**:
   - Ensure the `S3AccessKeyID` and `S3SecretAccessKey` are valid and have the required permissions.

3. **Upload Failures**:
   - Check the log file for detailed error messages.
   - Ensure the S3 bucket and destination folder exist.

4. **Log File Issues**:
   - Ensure the script has write permissions to the log directory.


## **Acknowledgments**
- AWS Tools for PowerShell: [AWS Tools for PowerShell Documentation](https://docs.aws.amazon.com/powershell/)
- PowerShell Documentation: [Microsoft PowerShell Docs](https://docs.microsoft.com/en-us/powershell/)
