# made by the scripting guys 11/28/14



Get-ADDomain | Select-Object InfrastructureMaster, RIDMaster, PDCEmulator

Get-ADForest | Select-Object DomainNamingMaster, SchemaMaster

Get-ADDomainController -Filter * |

     Select-Object Name, Domain, Forest, OperationMasterRoles |

     Where-Object {$_.OperationMasterRoles} |

     Format-Table -AutoSize