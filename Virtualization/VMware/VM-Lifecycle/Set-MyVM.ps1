# LEGAL
<# LICENSE
    MIT License, Copyright 2022 Richard Smith

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
#>
# GENERAL SCRIPT INFORMATION
<#
.NAME
    Set-MyVM.ps1.txt

.DESCRIPTION
    Scaffold for a virtual-machine setup script requiring the HyperV and VMware modules (initializations and functions sections).

.FUNCTIONALITY
    VM setup scaffold (Hyper-V/VMware).

.URL
    See location for notes and history:
    https://github.com/rsmith7712
        PowerShell Scripts
#>

#requires -Module HyperV, VmWare

<#






#>
########################## INITIALIZATIONS ##########################


##########################   FUNCTIONS     ##########################

[CmdletBinding()]
param{
	[Parameter(Mandatory)]
	[string]$VmName,
	
	[Parameter()]
	
	[ValidateSet('HyperV', 'VmWare')]
		[string]$Hypervisor
	}
	
switch ($Hypervisor){
	'HyperV'{
		# Use the Start-VM cmdlet in the HyperV module to start a VM 
		Start-VM -Name $VmName
		
		# Do some stuff to the VM here
		
		# Use the Stop-VM cmdlet in the HyperV module to stop the VM 
		Stop-VM -Name $VmName
		
		Break
		}
	'VmWare'{
		# Use whatever command the VmWare module has in it to start the VM 
		Start-VM -Name $VmName
		
		# Do stuff to the VmWare VmName
		
		# Use whatever command the VmWare module has in it to stop the VM 
		Stop-VM -Name $VmName
		
		Break
		}
	default{
		#Message
		"The hypervisor you passed [$_] is not supported"
		}
	}
	

########################## SCRIPT STARTS   ##########################


	
	
	
	
	
	
	