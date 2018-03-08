<#	
	.NOTES
	===========================================================================
	 Version: 1.2.1
     Created on:   	3/2/2018
     Modified on:   3/6/2018
	 Author:   	Alberto de la Torre
	 Organization: 	Roivant Sciences  	
	===========================================================================
	.DESCRIPTION
		New user creation script.  Guided questionaire workflow.
        Updated to work in multiple Vant domains.
        A log is generated and placed in \\rs-ny-nas\shared\it\PowershellOutput\NewHireAccounts.
        Please feel free to contact me with questions, ideas or concerns.

    .HOW TO USE
        Copy and run this script on a domain controller.  Right-click Powershell and "Run as Administrator". 
		Default security groups are imported from respective Vants located in \\rs-ny-nas\shared\IT\Powershell\Scripts\New-VantADUser\Default_Security_Groups
			Create your respective vant CSV if one does not exist.  Maintain naming convention as "xxxvant-Consultant.csv" or "xxxvant-Employee.csv"
#>

$LogRoot = "\\rs-ny-nas\shared\it\PowershellOutput\NewHireAccounts"

###########################################################################################
## DO NOT MODIFY BELOW THIS LINE ##########################################################
###########################################################################################
$localDC = "localhost"

#Determine logon domain
$localDomain = $(Get-ADDomain |select name).name
$localDomain = $localDomain.Substring(0,1).toupper() +$localDomain.Substring(1).tolower()

#Set user share based on domain
switch ($localDomain)
{
    'Myovant' {$NASroot = "\\mv-sf-nas\users"}
    'Axovant' {$NASroot = "\\as-ny-nas\users"}
    Default {
        #All other domains will default to NY 
        $NASroot = "\\rs-ny-nas\users$"
        }
}

#Set employment status and defaults
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Choose new hire status: "
Write-Host " `
    1 - Consultant
    2 - Employee
"
do
{
    $empStatus = Read-Host "Select number value of status: "
}
until ($empStatus -match '\b[1-2]\b')

$defaultSGpath = "\\rs-ny-nas\shared\IT\Powershell\Scripts\New-VantADUser\Default_Security_Groups"
switch ($empStatus)
{
    '1' {
        $empOU = "Consultants"
        $SGs = Import-Csv "$defaultSGpath\$localDomain-Consultants.csv"
    }
    '2' {
        $empOU = "Employees"
        $SGs = Import-Csv "$defaultSGpath\$localDomain-Employees.csv"
    }
    Default {}
}

#Set location and defaults
Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow "Select Location from list below: "
Write-Host " `
    1 - Basel
    2 - Cambridge
    3 - Durham
    4 - NYC
    5 - San Francisco
"
do
{
    $Location = Read-Host "Select by entering number value of location: "
}
until ($Location -match '\b[1-5]\b')

switch ($Location)
{
    '1' {
        $StreetAddress = "Viadukstrasse 8"
        $City = "4051 Basel"
        $State = ""
        $PostCode = "" 
        $Country = "CH" 
        $Company = "$localDomain Sciences"
        $OULocation = "OU=$empOU,OU=$localDomain Sciences,DC=$localDomain,DC=Local"
        $LogPath = "$LogRoot\Basel"
    }

    '2' {
        $StreetAddress = "90 Broadway"
        $City = "Cambridge"
        $State = "MA"
        $PostCode = "02142" 
        $Country = "US" 
        $Company = "$localDomain Sciences"
        $OULocation = "OU=$empOU,OU=$localDomain Sciences,DC=$localDomain,DC=Local"
        $LogPath = "$LogRoot\Cambridge"
    }

    '3' {
        $StreetAddress = "324 Blackwell St. Suite 1220, Bay 12"
        $City = "Durham"
        $State = "NC"
        $PostCode = "27701" 
        $Country = "US" 
        $Company = "$localDomain Sciences"
        $OULocation = "OU=$empOU,OU=$localDomain Sciences,DC=$localDomain,DC=Local"
        $LogPath = "$LogRoot\Durham"
    }

    '4' {
        $StreetAddress = "320 West 37th Street"
        $City = "New York"
        $State = "NY"
        $PostCode = "10018" 
        $Country = "US" 
        $Company = "$localDomain Sciences"
        $OULocation = "OU=$empOU,OU=$localDomain Sciences,DC=$localDomain,DC=Local"
        $LogPath = "$LogRoot\NYC"
    }

    '5' {
        $StreetAddress = "2000 Sierra Point Parkway"
        $City = "Brisbane"
        $State = "CA"
        $PostCode = "94005" 
        $Country = "US" 
        $Company = "$localDomain Sciences"
        $OULocation = "OU=$empOU,OU=$localDomain Sciences,DC=$localDomain,DC=Local"
        $LogPath = "$LogRoot\San_Francisco"
    }
    Default {}
}


function Grant-userFullRights {            
 [cmdletbinding()]            
 param(            
 [Parameter(Mandatory=$true)]            
 [string[]]$Files,            
 [Parameter(Mandatory=$true)]            
 [string]$UserName            
 )            
 $rule=new-object System.Security.AccessControl.FileSystemAccessRule ($UserName,"FullControl","Allow")            

 foreach($File in $Files) {            
  if(Test-Path $File) {            
   try {            
    $acl = Get-ACL -Path $File -ErrorAction stop            
    $acl.SetAccessRule($rule)            
    Set-ACL -Path $File -ACLObject $acl -ErrorAction stop            
    Write-Host "Successfully set permissions on $File"            
   } catch {            
    Write-Warning "$File : Failed to set perms. Details : $_"            
    Continue            
   }            
  } else {            
   Write-Warning "$File : No such file found"            
   Continue            
  }            
 }            
}



# Acquiring unique field data
$GivenName = Read-Host 'Input new users First Name'
$Initial = Read-Host -Prompt 'Input new users middle initial'
$Surname   = Read-Host 'Input new users Last Name'

do
{
    $empStartDate = Read-Host 'Employee start date.  Enter as MMDD value.'
}
until ($empStartDate -match '\b\d{4}\b' )

$SAMAccountName = $GivenName.ToLower() + "." + $Surname.ToLower()
Write-Verbose "$samaccountname" -Verbose

if(Get-ADUser -Filter "samaccountname -eq '$samaccountname'"){
    Write-Warning "user $samaccountname alread exists"
    $SAMAccountName = $GivenName.ToLower() + "." + $Surname.ToLower() + "." + $Initial.ToLower()
}

$DisplayName = $GivenName + " " + $Surname
$Title = Read-Host -Prompt 'Input new users title'
$Department = Read-Host -Prompt 'Input new users department'
$Office = $City
$Phone = Read-Host -Prompt 'Input new users phone.555-423-6262   for main office, mobile # for field staff'
$Fax = Read-Host -Prompt 'Input new users fax.555-423-6323   for Main Office'
$Mail = $GivenName.ToLower() + "." + $Surname.ToLower() + "@$localDomain.com"
$UserPrincipalName = $Mail
$Description = $Department

$defaultPW = $("$localDomain$" + "$($GivenName.tolower().substring(0,1))" + "$($Surname.tolower().substring(0,1))" + "$empStartDate")

$UserHomeDir = "$NASroot\$SAMAccountName"


$splat = @{
Path = $OULocation
SamAccountName = $SAMAccountName.ToLower()
GivenName = $GivenName
Initial = $Initial
Surname = $Surname
Name = $DisplayName
DisplayName = $DisplayName
EmailAddress = $Mail
UserPrincipalName = $Mail
Title = "$Title"
Description = $Description
Enabled = $true
ChangePasswordAtLogon = $false
PasswordNeverExpires  = $false
Fax = $Fax
OfficePhone = $Phone
Office = $Office
Department = $Department
StreetAddress = $StreetAddress
City = $City 
State = $State 
PostalCode = $PostCode  
Country = $Country 
Company = $Company
HomeDrive = "U:"
HomeDirectory = "$UserHomeDir"
}
    Write-Host -ForegroundColor Yellow -BackgroundColor DarkGreen "`n`nREVIEW INFORMATION"
    $splat

    Write-Host -BackgroundColor darkgreen  "----- DEFAULT PASSWORD ------"
    write-host -ForegroundColor Yellow "`t $defaultPW"
    Write-Host -BackgroundColor DarkGreen  "-----------------------------"


Write-Host -BackgroundColor Red "Do you want to proceed?"
$answer = Read-Host "(Y)es or (N)o "

switch ($answer)
    {
        'Y' {
            New-ADUser @splat -AccountPassword (ConvertTo-SecureString $defaultPW -AsPlainText -Force) -Server "$localDC"
            New-Item -Path $UserHomeDir -ItemType Directory -Force

            ## LOGGING #######################
            $UserLogPath = $LogPath + "\$(get-date -format yyyy)\$(Get-Date -Format MMdd)\$SAMAccountName\"

            if (!(Test-Path $UserLogPath))
            {
                New-Item -Path $UserLogPath -ItemType Directory -Force
            }

            $ADCreateLog = "$SAMAccountName-Create_AD.txt"

            "Account created by: $env:USERNAME" |Out-File $("$UserLogPath" + "$ADCreateLog")

            $splat | Out-File $("$UserLogPath" + "$ADCreateLog") -Append
            <# Remove default password logging for now
            "DEFAULT PASSWORD: $defaultPW" | Out-File $("$UserLogPath" + "$ADCreateLog") -Append
            #>
            

            foreach ($i in $SGs)
            {
                Add-ADGroupMember -Identity "$($i.Name)" -Members "$SAMAccountName" -Server "$localDC"
            }
            sleep -Seconds 5
            Get-ADPrincipalGroupMembership -Identity $SAMAccountName |select name|sort name |Export-Csv -NoTypeInformation -Path "$("$UserLogPath" + $SAMAccountName + "-GroupMemberships.csv")"
            

            #Final touches
            Grant-userFullRights -Files "$UserHomeDir" -UserName "$SAMAccountName"

            Write-Host -BackgroundColor DarkGreen "Log Output: $UserLogPath"

        
        }

        'N' {Write-Host -BackgroundColor Yellow -ForegroundColor Black "User creation cancelled."}
        default {Write-Host -BackgroundColor Yellow -ForegroundColor Black "Invalid answer. User creation cancelled."}
    }
