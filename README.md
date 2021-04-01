# Nellab-MRI-Pipeline
Guidance on processing anatomical MRI data from NYUAD

MRI Data Storage: Suggested Protocols
February 7 2019
For clarifications email Graham (graham.flick@nyu.edu)
			** MAC ONLY **

		****** BEFORE YOU START *******

*Add the participant to the "MRI_Participant_INFO" document.
*Add the MRI number and sharing info to the NYUAD NeLLab Participants Sheet.
*You will need a Matlab version beyond 2016a.

*Make sure that you have the following 2 Drives mounted on your computer
	smb://10.230.16.16/MEG2
	smb://rcsfileshare.abudhabi.nyu.edu/nifti_converted

If you do not have access to these drives, you will need to contact:
Julien - for MEG2 (NeLLab members only)
Osama - for nifti_converted

* For the Freesurfer processing, you will need access to Dalma from the
high performance computing cluster team. See here:
https://wikis.nyu.edu/display/ADRC/HPC
-You'll need to be somewhat familiar with basic linux commands to run this.
There are tutorials and other info on the HPC wiki.

You'll also need to install the matlab toolbox for handling .nii files:
https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image


		*******************************
		 	Data Formatting
		*******************************

1) After acquisition, Haidee will transfer the data to /Volumes/nifti_converted (this may change)

2) Copy this folder to our server MEG2/MRI_Data/data/nifti_converted so that we have a copy.

3) Run the HCP Preprocessing MATLAB script (USER INPUT REQUIRED) to convert this to HCP-format.

A template copy of this is available in MEG2/MRI_Data/User_Scripts/Template_Scripts.
Your own version of this can be kept in MEG2/User_Scripts.

* Set the subjectId to the MEG subject number (e.g. ‘A0167’) so that it can be used w. MEG.
* Set the sourcefolder to /Volumes/MEG2/MRI_Data/data/nifti_converted
* Set the targetfolder to /Volumes/MEG2/MRI_Data/data/HCP
* Change fieldMap file names to those in the source folder.
* leave the GRE file fields empty, it will find them.

Note: There should be 3 separate GRE files. Sometimes 2 of these files get placed in the same folder. You will just need to make another GRE folder in the subject's main folder and cut and paste one set of the GRE files that were incorrectly placed in the same folder into that new folder in the subject's main folder.

4) After running, confirm that the data have been saved to MRI_Data/data/HCP
* The MATLAB Script should output a Figure of 2 magnitude maps, and the phase difference.

		*******************************
			Preprocessing
		*******************************

5) Copy the HCP format data to /scratch on Dalma. Here's an example of how to do that from Terminal:
scp -r A0167 netid@dalma.abudhabi.nyu.edu:/scratch/netid

Note: Sometimes you need the entire line of code if it has trouble finding the volumes, or if you're not in the root folder so you can also run the following code from Terminal:
scp -r /Volumes/MEG2/MRI_Data/data/HCP/subjectID netid@dalma.abudhabi.nyu.edu:/scratch/netid/subjectID 

6) SSH onto Dalma:
ssh netid@dalma.abudhabi.nyu.edu

7) Change your directory to /scratch , which is where we'll run things.
cd $SCRATCH

7) Load the braincore module:
module load braincore/1.0

8) Run the pipeline script (~12 hours to complete)
run-pipeline.sh -d /scratch/netid -s A0167 -b prefs -e postfs

*To check on the status of the job(s) type:
squeue -u netid

*Under "ST" it will have "R" for running, "PD" for pending, and "CD" for completed.
*It will also tell you which jobs are dependent upon others.

*Errors are logged in /subjectID/logs

*The freesurfer output will be in subjectID/T1w/subjectID

9) Copy the data back to MEG2. Run this on your local computer:
scp -r netid@dalma.abudhabi.nyu.edu:/scratch/netid/subjectID/T1w/subjectID /Volumes/MEG2/MRI_Data/data/Post_FS/

*** The folder that you will want to copy to the MRI folder for your experiment is located
*** at Post_FS/SubjectID/T1w/SubjectID.


		**************************************************
			Prep for MEG Source Reconstruction
		**************************************************

10) Open up Terminal on your computer, and start a unix shell session by typing:
tcsh

11) Set up some environment variables that we need. Customize this to your computer:

setenv SUBJECTS_DIR /Users/megstaff/ExperimentName/mri # Where MRI folders are being kept

setenv FREESURFER_HOME /Applications/freesurfer # Where freesurfer is (should be the same)
source $FREESURFER_HOME/SetUpFreeSurfer.csh

cd $SUBJECTS_DIR

setenv SUBJECT subjectID # The subject id you’re currently working on.

12) Create the .seghead files for bem generation by typing:
mkheadsurf -subjid $SUBJECT

13) Now, in a separate Terminal window where you've activated the men environment, and then created a new unix shell via repeating steps 10 and 11, generate the bem (this takes a little while):
mne watershed_bem --subject $SUBJECT

Sanity Check: Sometimes you may forget which subject you were working on in a Unix shell and then when you go to generate the bem, you're wondering which one is already processed. The check is to see which folders were edited and it should be mri, scripts, and surf.

*** You are now ready to start mne-python preprocessing with this subject’s MRI.

*** To confirm that everything is in order, start a coregistration GUI, and check that the
*** ptp’s MRI and head model load when you select them from the drop-down menu (top-left).
*** You will need to manually enter the location of the fiducial landmarks using the mouse.

*** For further sanity checks, see MRI_Data_SanityChecks.py
