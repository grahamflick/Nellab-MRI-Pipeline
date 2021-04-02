
% script to convert to HCP format data
clear all
close all
clc

%% Users's input 
modality = '3T'; %specify source of data:'3T' for structurals

%% User Input Required here:

% 1. The source folder: where the data are 
sourceFolder = '/Volumes/mri/data/nifti_converted/NELLAB/Sub0197_Lp_Structurals'
% 2. The subject ID upon output: You probably want to set this to be the MEG subject number
subjectId='testOA';
% 3. Where you want the data tto be saved. This should probably be /Volumes/MEG2/MRI_Data/data/HCP/{subjectID}
targetFolder=['/Volumes/MEG2/MRI_Data/data/HCP/' subjectId]; 

%% convert what? Choose which are needed. In most cases both should be set to 1.
StructrualFlag = 1;
GRE_Flag =1;

%Users's input done


%% Making Directories in Target Folder
T1List = dir([sourceFolder '/*anatT1W*']);
T2List = dir([sourceFolder '/*anatT2W*']);
GREList = dir([sourceFolder '/*fmap_acqge*'])
mkdir(targetFolder)
cd(targetFolder)
mkdir('unprocessed')
cd('unprocessed')
mkdir(modality)
cd(modality)

tic

 
  %% Create Structrual T1w and T2w folders
  if StructrualFlag
      for T1Ind = 1:2:numel(T1List) %skip every other folder to skip the "intensity corrected" images
          T1Dir = ['T1w_MPR' num2str(T1Ind)];
          mkdir(T1Dir);
          newfilename = [targetFolder '/unprocessed/' modality '/' T1Dir '/' subjectId '_' modality '_T1w_MPR' num2str(T1Ind) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
          origfile = dir([sourceFolder '/' T1List(T1Ind).name '/*.nii.gz']); %returns a structure with folder and name of the file
          copyfile([origfile.folder '/' origfile.name], newfilename);
         
      end
      
      for T2Ind = 1:2:numel(T2List) %skip every other folder to skip the "intensity corrected" images
          T2Dir = ['T2w_SPC' num2str(T2Ind)];
          mkdir(T2Dir);
          newfilename = [targetFolder '/unprocessed/' modality '/' T2Dir '/' subjectId '_' modality '_T2w_SPC' num2str(T1Ind) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
          origfile = dir([sourceFolder '/' T2List(T2Ind).name '/*.nii.gz']); %returns a structure with folder and name of the file
          copyfile([origfile.folder '/' origfile.name], newfilename);
          
      end
  end
 %% GRE Field Map perperation 
 %Convention requires SubjectID_Modality_FieldMap_Magnitude.nii.gz and SubjectID_Modality_FieldMap_Phase.nii
 % note the magnitude images contains 2 volumes at different TEs
if GRE_Flag 
if size(GREList,1) == 3
    GREList1 = dir(fullfile(GREList(1).folder, GREList(1).name, '*.nii.gz')); %dir([sourceFolder '/' GRE_FieldMap_1 '/*gre*.nii.gz']);
    GREList2 = dir(fullfile(GREList(2).folder, GREList(2).name, '*.nii.gz'));
    GREList_phase = dir(fullfile(GREList(3).folder, GREList(3).name, '*.nii.gz'));
elseif  size(GREList,1) == 2
    GREmag = dir(fullfile(GREList(1).folder, GREList(1).name, '*.nii.gz')); %dir([sourceFolder '/' GRE_FieldMap_1 '/*gre*.nii.gz']);
    GREList1 = GREmag(1);
    GREList2 = GREmag(2);
    GREList_phase = dir(fullfile(GREList(2).folder, GREList(2).name, '*.nii.gz'));
else
    
    error('No GRE Field maps found')
end
magFileName = [subjectId '_' modality '_FieldMap_Magnitude.nii.gz'];
phaseFileName = [subjectId '_' modality '_FieldMap_Phase.nii.gz'];

   magn = load_untouch_nii([GREList1.folder '/' GREList1(1).name]);
   magn2 = load_untouch_nii([GREList2.folder '/' GREList2(1).name]);
   magn.img(:,:,:,2) = magn2.img;
   magn.hdr.dime.dim(5) = 2;
   magn.hdr.dime.dim(1) = 4;
   save_untouch_nii(magn, [targetFolder '/unprocessed/' modality '/T1w_MPR1/' magFileName])
   copyfile([GREList_phase(1).folder '/' GREList_phase(1).name], [targetFolder '/unprocessed/' modality '/T1w_MPR1/' phaseFileName]);
   save_untouch_nii(magn, [targetFolder '/unprocessed/' modality '/T2w_SPC1/' magFileName])
   copyfile([GREList_phase(1).folder '/' GREList_phase(1).name], [targetFolder '/unprocessed/' modality '/T2w_SPC1/' phaseFileName]);

   % For Quality Assurance, verify correct images were saved
   figure,
   phs = load_untouch_nii([GREList_phase.folder '/' GREList_phase(1).name]);
   subplot(1,3,1), imagesc(magn.img(:,:,round(magn.hdr.dime.dim(4)/2),1)), colormap gray, axis image,  title('First Mag Image')
   subplot(1,3,2), imagesc(magn.img(:,:,round(magn.hdr.dime.dim(4)/2),2)),  colormap gray, axis image,title('Second Mag Image')
   subplot(1,3,3), imagesc(phs.img(:,:,round(phs.hdr.dime.dim(4)/2),1)),  colormap gray, axis image,title('Phase Difference Image')
  

end


t = toc/60; 
