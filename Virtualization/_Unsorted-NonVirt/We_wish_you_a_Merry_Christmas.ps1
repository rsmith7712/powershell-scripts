try {
Add-Type -TypeDefinition @"
    public enum Duration
    {
        WHOLE     = 1600,
        HALF      = WHOLE/2,
        QUARTER   = HALF/2,
        EIGHTH    = QUARTER/2,
        SIXTEENTH = EIGHTH/2,
    }
"@
}
catch{ }

function ConvertTo-NoteFrequency {
    <#
        .SYNOPSIS
            Convert note names to MIDI note number and frequency.
        .DESCRIPTION
            This function takes a note name and will convert it to it's MIDI note number
            as well as the frequency of the note. It uses the 12-tone scale and
            supports both the 'regular', and the 'German' scale where 'H' is used instead of 'B'.
        .EXAMPLE
            ConvertTo-NoteFrequency 'A#4'
        .EXAMPLE
            ConvertTo-NoteFrequency 'b5' -UseAlternateScale
        .EXAMPLE
            (ConvertTo-NoteFrequency 'e5').Play(200)
        .EXAMPLE
            (ConvertTo-NoteFrequency 'e5').Play([Duration]::QUARTER)
        .NOTES
            Author: Øyvind Kallstad
            Date: 14.12.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param (
        # The name of the note.
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string] $Note,

        # Default octave to append to note if none are present.
        [Parameter()]
        [ValidateRange(0,8)]
        [int] $DefaultOctave = 0,

        # Use this switch to use the alternate scale used in parts of northern europe where B = H.
        [Parameter()]
        [switch] $UseAlternateScale
    )

    # split note input into the note part and the octave part
    $noteSplit = $Note -split '(\d)'
    $noteName = $noteSplit[0]
    [int]$octave = $noteSplit[1]
    Write-Verbose "Note Name: $noteName"

    # convert to lower case
    $noteName = $noteName.ToLower()

    # replace flats with sharps
    $noteName = $noteName -replace 'db', 'c#'
    $noteName = $noteName -replace 'eb', 'd#'
    $noteName = $noteName -replace 'gb', 'f#'

    # handle alternate scale
    if($UseAlternateScale) {
        $scale  = @('a','a#','h','c','c#','d','d#','e','f','f#','g','g#')
        $noteName = $noteName -replace 'b', 'a#'
        $regexString = '^[acdefgh]#{0,1}$'
    }
    else {
        $scale  = @('a','a#','b','c','c#','d','d#','e','f','f#','g','g#')
        $noteName = $noteName -replace 'bb', 'a#'
        $regexString = '^[abcdefg]#{0,1}$'
    }

    Write-Verbose "Note Name after conversion: $noteName"

    # validate note name
    if (-not($noteName -match $regexString)) {
        Write-Warning "'$($Note)' is not a valid note name!"
    }

    else {
        # if no octave information is given, add default octave
        if(-not($octave)) {
            $octave = $DefaultOctave
        }
        Write-Verbose "Ocatave: $octave"

        # if note is above 'c', subtract 1 to the octave - since 'c' marks the beginning of the next octave
        $inputOctave = $octave
        if(-not($scale[0..2] -contains $noteName)) {
            if($octave -gt 0) {
                $octave--
                Write-Verbose "Octave after conversion: $($octave)"
            }
        }

        # find the number of half-steps up from 'A'
        $halfSteps = 0
        foreach ($scaleNote in $scale) {
            if(-not($scaleNote -eq $noteName)) {
                $halfSteps++
            }
            else {
                break
            }
        }
        Write-Verbose "Number of half-steps up from A: $($halfSteps)"

        # we initially set the frequency of A0
        # then update it with the frequency of 'A' in the same octave as the Note
        $aFrequencyInNoteOctave = 27.5
        for ($i = 0; $i -lt $octave; $i++) {
            $aFrequencyInNoteOctave = $aFrequencyInNoteOctave * 2
        }
        Write-Verbose "The frequency of 'A' in octave $($octave) is $($aFrequencyInNoteOctave)"

        # calculate the note frequency
        $noteFrequency = [math]::Pow([math]::Pow(2,(1/12)),$halfSteps) * $aFrequencyInNoteOctave

        # calculate the MIDI note number of the note
        $midiNoteNumber = [math]::Round(12 * [math]::Log(($noteFrequency/440),2)) + 69

        $output = New-Object -TypeName 'PSObject'
        $output | Add-Member -MemberType NoteProperty -Name 'Input' -Value $Note
        $output | Add-Member -MemberType NoteProperty -Name 'Note' -Value ($notaName + $inputOctave)
        $output | Add-Member -MemberType NoteProperty -Name 'Frequency' -Value $noteFrequency
        $output | Add-Member -MemberType NoteProperty -Name 'MidiNumber' -Value $midiNoteNumber
        $output | Add-Member -Name 'Play' -MemberType ScriptMethod -Value {param([int]$Length)[System.Console]::Beep($this.Frequency,$Length)}
        
        Write-Output $output
    }
}

# define melody
$melody = @(
    @('g4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('c5',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('c5',[Duration]::EIGHTH),
    @('d5',[Duration]::EIGHTH),
    @('c5',[Duration]::EIGHTH),
    @('b4',[Duration]::EIGHTH),
    @('a4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('a4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('a4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('d5',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('d5',[Duration]::EIGHTH),
    @('e5',[Duration]::EIGHTH),
    @('d5',[Duration]::EIGHTH),
    @('c5',[Duration]::EIGHTH),
    @('b4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('g4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH)
    @('g4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('e5',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('e5',[Duration]::EIGHTH),
    @('f5',[Duration]::EIGHTH),
    @('e5',[Duration]::EIGHTH),
    @('d5',[Duration]::EIGHTH),
    @('c5',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('a4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('g4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('a4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('d5',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('b4',[Duration]::EIGHTH), @('PAUSE',[Duration]::SIXTEENTH),
    @('c5',[Duration]::EIGHTH)
)

# play melody
foreach ($note in $melody) {
    if (-not($note[0] -eq 'PAUSE')) {
        (ConvertTo-NoteFrequency $note[0]).Play($note[1])
    }
    else {
        Start-Sleep -Milliseconds $note[1]
    }
}