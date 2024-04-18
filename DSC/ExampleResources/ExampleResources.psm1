[DscResource()]
class Tailspin {
    [DscProperty(Key)] [TailspinScope]
    $ConfigurationScope

    [DscProperty()] [TailspinEnsure]
    $Ensure = [TailspinEnsure]::Present

    [DscProperty(Mandatory)] [bool]
    $UpdateAutomatically

    [DscProperty()] [int] [ValidateRange(1, 90)]
    $UpdateFrequency

    hidden [Tailspin] $CachedCurrentState
    hidden [PSCustomObject] $CachedData

    [Tailspin] Get() {
        $CurrentState = [Tailspin]::new()
        return $CurrentState
    }

    [bool] Test() {
        return $true
    }

    [void] Set() {}
}
enum TailspinScope {
    Machine
    User
}
enum TailspinEnsure {
    Absent
    Present
}