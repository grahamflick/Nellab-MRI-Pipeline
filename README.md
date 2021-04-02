# Nellab-MRI-Pipeline
Guidance on processing anatomical MRI data from NYUAD

* Please note that the following instructions are intended for use on a MAC. *

# BEFORE YOU START

(1) You will need access to Dalma from the high performance computing cluster team. See here for requesting an account and completing the training:
https://wikis.nyu.edu/display/ADRC/HPC and https://wikis.nyu.edu/display/ADRC/Accounts

You will need to be somewhat familiar with basic linux commands to navigate Dalma. There are tutorials and other info on the NYUAD HPC wiki above.

(2) You will need to complete Advanced MRI Safety Training for Healthcare Professionals in order to get access to the /mri-nellab server. See here: https://www.appliedradiology.org/courses.aspx. Once complete, email the certificate of completion to Haidee Paterson (hp42@nyu.edu) and Osama Abdullah (osama.abdullah@nyu.edu) and request permission to access the mri-nellab server.

___ If you do not complete the above two steps, you will be unable to do any of the remaining steps. ___

(3) Add the participant to the "MRI_Participant_INFO" document.

(4) Add the MRI number and sharing info under "MRI Information" to the NELLAB-AD Participants Google Sheet.

(5) Make sure you have a Matlab version beyond 2016a installed on your MAC.

(6) Make sure that you have the following 2 Drives mounted on your computer:

	smb://rcsfileshare.abudhabi.nyu.edu/mri-nellab

	smb://rcsfileshare.abudhabi.nyu.edu/MEG2

If you do not have access to these drives, you will need to contact:
nyuad.it.help@nyu.edu

	NOTE: access to /mri-nellab requires completion of (2) above.

(7) You'll need to install the MATLAB toolbox for handling .nii files:
https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image

# Step 1: Converting to HCP Format.

After the MRI Data are acquired, the MRI tech will convert them to nifti formats and upload them to the MRI Server directory designated for our lab, /mri-nellab. The first step in preprocessing is to convert these files into the format required by the Human Connectome Project, which is compatible with our pipelines in MNE-Python. This requires the following steps;

1) After acquisition, Haidee will transfer the participant's data as one folder to /mri-nellab. Copy this folder to our server /MEG2/MRI_Data/data/nifti_converted so that we have a copy.

2) Next, set up the HCP Preprocessing MATLAB script to convert this to HCP-format. A template copy of this script is available in:

/MEG2/MRI_Data/User_Scripts/Template_Scripts
https://github.com/grahamflick/Nellab-MRI-Pipeline/tree/main/matlab_templates

Please copy your own version of this and save it in /MEG2/User_Scripts. Please *do not overwrite* the template script.

After you have copied it into /User_Scripts, it's recommended to change the name of the script to include the Participant ID, e.g. main_HCP_from_nifti_A0167.m, for replicability.

3) Open the script. You will need to make the following changes to the "where is source nifti data located?" section in your copied template version of the script *before you run it:*

	i. Set the subjectId to the MEG subject number (e.g. ‘A0167’) so that it can be used with MEG.

	ii. Set the sourcefolder to /Volumes/MEG2/MRI_Data/data/nifti_converted/(folder copied from /mri-nellab)

	iii. Set the targetfolder to /Volumes/MEG2/MRI_Data/data/HCP

4) Run the script. It should output a Figure of 2 magnitude maps, and the phase difference. After running, confirm that the data have been saved to /MRI_Data/data/HCP. Look for a recently created folder with the given participant ID.

# Step 2: Freesurfer reconstruction on Dalma.

The biggest step in preprocessing is the Freesurfer reconstruction of the cortical surface from the MRI volumes. The MRI volumes are images stacked on top of each each other, with each image representing one slice of the brain. We want a three-dimensional model of the cortical *surface*, capturing all of the grooves and folds. Freesurfer's **recon-all** function will do this for us. First though, we will copy the data to a remote server located at NYUAD, where we will eventually run the reconstruction algorithm.

1) Copy the HCP format data to /scratch on Dalma. To do this, you will need to open a Terminal window, change directories to /MEG2/MRI_Data/data/HCP, and use the secure copy command "scp". Here's an example:
```
scp -r A0167 netid@dalma.abudhabi.nyu.edu:/scratch/netid
```

The first part of this command is the name of the command (scp). The -r tells the command that you want it to operate recursively, meaning that you want to copy all of the contents of the the folder you direct it to. "A0167" is the name of the subject folder that we want to copy. "netid@dalma..." is the location that we want to send the folder to. In this case, I am copying it to the Dalma remote server and placing it in the scratch/netid folder. You will need to replace "netid" with your own netid, both at the beginning and end of the destination name.

**Note**: Sometimes you need the entire line of code if it has trouble finding the volumes, or if you're not in the root folder so you can also run the following code from Terminal:
```
scp -r /Volumes/MEG2/MRI_Data/data/HCP/subjectID netid@dalma.abudhabi.nyu.edu:/scratch/netid/subjectID
```

2) SSH onto Dalma. SSH is a way to connect to a remove server via the command line. Open a new terminal (or use the same one as above) and type the following, replacing "netid" with your own netid:
```
ssh netid@dalma.abudhabi.nyu.edu
```

This should prompt you for your NYU password. Once you have provided it, you will be "logged in" to the remote server. This means that you are running commands on Dalma, in this window, rather than on your own computer.

3) Change your directory to /scratch, which is where we'll run the Freesurfer algorithm:
```
cd $SCRATCH
```

4) Load the braincore module. In order to use the command we need, we need to load a certain group of functions. To do this, type the following and hit enter:
```
module load braincore/1.0
```

5) Now it's time to actually run the surface reconstruction script. Type the following command in the same Terminal window where you are logged in to Dalma via SSH. This will take quite a while to run, *often up to 12 hours*. Make sure that you replace "netid" with your netid and "A0167" with your subject's number.
```
run-pipeline.sh -d /scratch/netid -s A0167 -b prefs -e postfs
```

(6) If there are no problems, this means you have successfully started a "job" on the remote Dalma server. You can check the status of this job by typing:
```
squeue -u netid
```
This will show you a set of all the jobs currently running, with their statuses ("ST"): "R" for running, "PD" for pending, and "CD" for completed.
This will also tell you which jobs are dependent upon others.

In the event that there are errors in your reconstruction, these will be logged in /subjectID/logs. The output of the run-pipeline.sh script will be put in subjectID/T1w/subjectID.

Because this job is running on the remote server, you can close the terminal and it will not impact the processing. If you do close the terminal and want to check the status of the job later, just SSH back onto Dalma (Step 2.2 above) and then run the squeue command.

7) Once the script is finished (~12 hours), copy the data back to MEG2, in the Post_FS folder. To do this, open a **new** Terminal on your local computer and type the following:
```
scp -r netid@dalma.abudhabi.nyu.edu:/scratch/netid/subjectID/T1w/subjectID /Volumes/MEG2/MRI_Data/data/Post_FS/
```

(8) You may then want to copy the subject's MRI data from the MEG2 server to your local computer to run coregistration and source estimation.

# Step 3: Prep for MEG Source Reconstruction

Now that we have the cortical surface reconstructed for our subject, we want to prepare it for coregistration and source estimation. To do so, we need to generate a head surface model and a boundary element model. This will be done in a tcsh session on your local computer.

1) Open a Terminal and activate an Anaconda environment where you have mne-python installed:
```
source activate MNE
```

2) Start a unix shell session by typing:
```
tcsh
```

3) Set up some environment variables that we need. Customize this to your computer:

The MRI folder is the SUBJECTS_DIR:

```
setenv SUBJECTS_DIR /Users/megstaff/ExperimentName/mri # Where MRI folders are being kept that you copied from /Post_FS
```
The directory where Freesurfer is installed. This is almost always the same:
```
setenv FREESURFER_HOME /Applications/freesurfer # Where freesurfer is (should be the same)
```

Now we will source the Freesurfer setup script by running:
```
source $FREESURFER_HOME/SetUpFreeSurfer.csh
```

And change directory to the Subjects Directory:
```
cd $SUBJECTS_DIR
```

Finally, set the subject ID variable. Change the "subjectID" to be equal to your subject's identify (e.g., A0167).
```
setenv SUBJECT subjectID # The subject id you’re currently working on.
```

4) Create the .seghead files for bem generation by typing:
```
mkheadsurf -subjid $SUBJECT
```

5) Generate the bem (this takes a little while):
```
mne watershed_bem --subject $SUBJECT
```

**Note**: Sometimes mkheadsurf and watershed_bem need to be run in separate tcsh windows. If you encounter issues running them in the same window, just open two separate Terminal windows and run them successively as follows: steps 3.1-3.3, 3.4 in one window, and then once complete, steps 3.1-3.3, 3.5 in another window.

You are now ready to start mne-python preprocessing with this subject’s MRI. To confirm that everything is in order, start a coregistration GUI, and check that the participant’s MRI and head model load when you select them from the drop-down menu (top-left). You will need to manually enter the location of the fiducial landmarks using the mouse.
