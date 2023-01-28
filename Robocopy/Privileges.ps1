
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


$Script:PrivilegesCsCode = @"
using System;
using System.Runtime.InteropServices;

 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
  phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
  ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public const string CreateToken         = "SeCreateTokenPrivilege";
  public const string AssignPrimaryToken        = "SeAssignPrimaryTokenPrivilege"; 
  public const string LockMemory          = "SeLockMemoryPrivilege"; 
  public const string IncreaseQuota       = "SeIncreaseQuotaPrivilege";
  public const string UnsolicitedInput    = "SeUnsolicitedInputPrivilege"; 
  public const string MachineAccount      = "SeMachineAccountPrivilege";
  public const string TrustedComputingBase      = "SeTcbPrivilege";
  public const string Security      = "SeSecurityPrivilege";
  public const string TakeOwnership       = "SeTakeOwnershipPrivilege"; 
  public const string LoadDriver          = "SeLoadDriverPrivilege";
  public const string SystemProfile       = "SeSystemProfilePrivilege"; 
  public const string SystemTime          = "SeSystemtimePrivilege"; 
  public const string ProfileSingleProcess      = "SeProfileSingleProcessPrivilege";
  public const string IncreaseBasePriority      = "SeIncreaseBasePriorityPrivilege"; 
  public const string CreatePageFile      = "SeCreatePagefilePrivilege";
  public const string CreatePermanent     = "SeCreatePermanentPrivilege";
  public const string Backup        = "SeBackupPrivilege";
  public const string Restore       = "SeRestorePrivilege"; 
  public const string Shutdown      = "SeShutdownPrivilege";
  public const string Debug         = "SeDebugPrivilege"; 
  public const string Audit         = "SeAuditPrivilege"; 
  public const string SystemEnvironment         = "SeSystemEnvironmentPrivilege";
  public const string ChangeNotify        = "SeChangeNotifyPrivilege"; 
  public const string RemoteShutdown      = "SeRemoteShutdownPrivilege";
  public const string Undock        = "SeUndockPrivilege";
  public const string SyncAgent           = "SeSyncAgentPrivilege";
  public const string EnableDelegation    = "SeEnableDelegationPrivilege"; 
  public const string ManageVolume        = "SeManageVolumePrivilege";
  public const string Impersonate         = "SeImpersonatePrivilege"; 
  public const string CreateGlobal        = "SeCreateGlobalPrivilege"; 
  public const string TrustedCredentialManagerAccess  = "SeTrustedCredManAccessPrivilege";
  public const string ReserveProcessor    = "SeReserveProcessorPrivilege"; 
  public static bool AddPrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
  public static bool RemovePrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_DISABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }


"@


function Register-TokenManipulator{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [Switch]$Force
    )
    
    $CsSource = $Script:PrivilegesCsCode 
    
    if (!("TokenManipulator" -as [type])) {
        Write-Verbose "Registering TokenManipulator... " 
        Add-Type -TypeDefinition "$CsSource"
    }else{
        Write-Verbose "CoreInternals already registered: TokenManipulator... " 
    }
}






<#
.Synopsis
    Enables or disables a privilege for the current process token.
.DESCRIPTION
   Enables or disables a privilege for the current process token.
.EXAMPLE
   Set-Privilege -Privilege SeDebugPrivilege 
.EXAMPLE
   Set-Privilege -Privilege SeAuditPrivilege -Disable
#>
function Set-Privilege {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        ## The privilege to adjust. This set is taken from
        ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
        [ValidateSet(
            "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
            "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
            "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
            "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
            "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
            "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
            "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
            "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
            "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
            "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege", "SeIncreaseQuotaPrivilege")]
        $Privilege,
        ## The process on which to adjust the privilege. Defaults to the current process.
        ## Switch to disable the privilege, rather than enable it.
        [Switch] $Disable
    )

    Register-TokenManipulator
    
    if($Disable){
        Write-Verbose "Removing Privilege $Privilege" 
        [TokenManipulator]::RemovePrivilege($Privilege)    
    }else{
        Write-Verbose "ADding Privilege $Privilege" 
        [TokenManipulator]::AddPrivilege($Privilege)    
    }
    
}
