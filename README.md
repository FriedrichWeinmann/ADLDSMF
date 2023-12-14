# Welcome to the AD LDS Management Framework

This little project tries to enable a simplified content provisioning for AD LDS Instances.
You provide the content as configuration settings (static or dynamic) and it will do the rest.

## Install

To install the module, run this line:

```powershell
Install-Module ADLDSMF -Scope CurrentUser
```

Or on an updated machine or the latest version of PowerShell:

```powershell
Install-PSResource ADLDSMF
```

## Profit

To use this system you need to provide the set of configuration settings to apply.
Afterwards, running the module against an LDS Instance will have it check for the defined content and create / update as needed.

Two examples have been provided in the `examples` folder, the following code assumes you have downloaded this github repository, imported the module and set the current path of your PowerShell console to the root path of this project.

> Example 1: Fixed Content

In this example, each configuration file only has static, hard-coded values and is placed in a folder matching its object type.

[Content](examples/1-plain-content)

```powershell
# Load Configuration
Import-LdsConfiguration -Path '.\examples\1-plain-content'

# Test / Preview changes against the AD LDS server
Test-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'

# Apply Changes
Invoke-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'
```

> Example 2: Dynamic Content

In this example, we have but a single configuration file, which defines all kinds of settings.
In contravention to PowerShell standards, this configuration file can define and interpret variables.

[Content](examples/2-dynamic/node-alpha.psd1)

```powershell
# Load Configuration
Import-LdsConfiguration -Path '.\examples\2-dynamic'

# Test / Preview changes against the AD LDS server
Test-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'

# Apply Changes
Invoke-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'
```

> Combining multiple configurations

It is perfectly possible to combine multiple configuration sets, simple call `Import-LdsConfiguration` multiple times:

```powershell
# Load Configurations
Import-LdsConfiguration -Path '.\examples\1-plain-content'
Import-LdsConfiguration -Path '.\examples\2-dynamic'

# Test / Preview changes against the AD LDS server
Test-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'

# Apply Changes
Invoke-LdsConfiguration -Server lds1.contoso.com -Partition 'DC=Fabrikam,DC=org'
```

> Clearing Configurations

To reset the loaded configuration settings, there are two options:

+ Import ADLDSMF again
+ Use `Reset-LdsConfiguration`

> User Account Passwords

When defining a user object through ADLDSMF, it is not possible to specify a password - it will be automatically generated for enabled user objects.
As this is usually not all that useful, you can use `Reset-LdsAccountPassword` to generate a new password and have it set to your clipboard.
You can also specify a custom password instead, if you need to bulk-assign passwords instead:

```powershell
# Interactive password reset
Reset-LdsAccountPassword -Name svc_whatever -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'

# Updating in bulk:
$users | ForEach-Object {
    Reset-LdsAccountPassword -Name $_.Name -Password $_.Password -Server lds1.contoso.com -Partition 'DC=fabrikam,DC=org'
}
```
