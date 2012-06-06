MIDI LP pipeline by Leonard Burtscher, burtscher@mpe.mpg.de
===
6 June 2012
===

--- Installation ---
This pipeline needs to know about three directories: itself, raw data, reduced data

Set the following environment variables
$MIDITOOLS		contains all scripts; must be in IDL's search path or loaded manually
$MIDIDATA		The pipeline expects raw data in this directory in subdirectories like 
				YYYY-MM-DD, where the date is the date of night begin. The filenames of 
				the individual FITS files must be the original ESO filename (ARCFILE 
				keyword in header). A valid path could look like this 
				$MIDIDATA/2009-12-02/MIDI.2009-12-03T02:38:41.823.fits
$MIDIREDDIR		The reduced data will be stored in this directory in subdirectories like 
				YYYY-MM-DD, i.e. the EWS 'tag' is $MIDIREDDIR/YYYY-MM-DD/HHMMSS. A popular 
				choice for this is '/tmp'. The output of EWS' oir1dCompress of the above 
				mentioned file is written to $MIDIDATA/2009-12-02/023423.compressed.fits

To add MIDITOOLS to your IDL path add the following to your STARTUP.pro:
!path =	EXPAND_PATH('+'+getenv('MIDITOOLS')) +  ':' + !path

Local configuration files and intermediate data products reside in $MIDITOOLS/local.
Example files are included in this package; you will have to modify them if you are
interested in different targets.

--- Features ---
- To reduce an observation call dr/lpw (see instructions there)
- To check the quality of an observation, run qc/obs_good (see instructions there)


To come:
- scripts to produce your own obs_db.sav
- scripts to reduce all observations of a target
- scripts to do simple fitting
- scripts to plot spectra, (u,v) planes etc., quality control plots
- scripts to do weak source calibration including decorrelation correction and taking into account conversion factor RMS