# Synchronisation between processes with Mutex

- How can one powershell script check if another powershell script is running? 
- How can you check if a native CPlusPlus application, CSharp application is running, or any other processes for that matter ?

This post explains how to use Mutex in PowerShell to do just that. 

## Mutexes

Its a synchronization primitive that grants exclusive access to the shared resource to only one thread. If a thread acquires a mutex, the second thread that wants to acquire that mutex is suspended until the first thread releases the mutex...

There are two types of Mutexes
- ***Local mutexes*** (which are unnamed), can only be used by any thread in our process that has reference to the Mutex Object.
- ***Named system mutexes***, visible throughout the Operating system and hence can be used as an interprocess synchronization mechanism. This is what we want.


### Mutex Creation

See [documentation](https://learn.microsoft.com/en-us/dotnet/api/system.threading.mutex.-ctor?redirectedfrom=MSDN&view=net-7.0#System_Threading_Mutex__ctor_System_Boolean_System_String_System_Boolean__)

```powershell
    $recvOwnerShip = $False # Stores Boolean value that, indicates whether the calling thread was granted initial ownership of the mutex.
    # Create the Mutex Object usin the constructuor -> Mutex Constructor (Boolean, String, Boolean)
    $mutex = New-Object -TypeName System.Threading.Mutex($true, "MutexName1", [ref]$recvOwnerShip)
    if($recvOwnerShip){
        Write-Host "[Mutex] Received Ownership"
    }else{
        Write-Host "[Mutex] Mutex in Use" -f Red
    }
```
--------------------------------------------------------------------------------------------------------

### Check for Ownership

Now the variable $recvOwnerShip will have $True if the current PowerShell process ,where you ran this code got a lock on the MutEx object, got ownership of it. You can open another PowerShell instance and verify that the only the first process has $recvOwnerShip set to True

```powershell
    $recvOwnerShip = $False # Stores Boolean value that, indicates whether the calling thread was granted initial ownership of the mutex.
    # Create the Mutex Object usin the constructuor -> Mutex Constructor (Boolean, String, Boolean)
    $mutex = New-Object -TypeName System.Threading.Mutex($true, "MutexName1", [ref]$recvOwnerShip)
    if($recvOwnerShip){
        Write-Host "[Mutex] Received Ownership"
    }else{
        Write-Host "[Mutex] Mutex in Use" -f Red
    }
```

### Lock current process to Wait on Mutex

So in your project which spans across multiple PowerShell scripts, the very first step will be try to acquire the lock during the creation of the Mutex Object. If you get the lock on the MutEx then very well, go ahead and use the shared resource say a config file. But if you don't get the lock on the MutEx then you have to call the ```WaitOne()``` method on the MutEx object.

There are multiple method overloads but we can simply use the WaitOne() method, which blocks the current PowerShell process until it receives the lock.

[WaitOne Documentation](https://learn.microsoft.com/en-us/dotnet/api/system.threading.waithandle.waitone?redirectedfrom=MSDN&view=net-7.0#System_Threading_WaitHandle_WaitOne)

```powershell
    # Blocks the current thread until the current WaitHandle receives a signal.
    $mutex.WaitOne()

    $mutex.Dispose()
```

### Release and Dispose the Mutex

```powershell
    $mutex.ReleaseMutex()
    $mutex.Dispose()
```
