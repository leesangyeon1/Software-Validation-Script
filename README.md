# Software-Validation-Script
 software and environment validation automation script designed to ensure the stability and consistency of compute environments before production use.

The system performs a comprehensive pre-deployment check across all compute nodes, verifying:

Linux distribution and kernel version

Slurm version and cluster connectivity

Loaded environment modules



Main idea: 
integrate the testing script with linux bash and application, software testing script from landing. 

1. application(software) test script
   there are unique testing script for each software that run in ondemand. 
   the output of the test script must includes 
	   custom tools 
	   loaded modules
	   additional kernel 
	   which partition it used(node)
	   when and how long it took for the test script
	   if the partition or modules are not founded in the testing script part, igrone and exclude it
	after the script > it will create the dir 'software test result' if its already exist, then direct it to the folder after it, make a directory for each software for example, if you run script in pycharm, make pycharm_testingResult dir and if it exsist, then put output file as ther same as other softwares. 
	 the Output file name have to formatted as (Name of Software + Date(when it got run))
	 example if I run Jupyter testing script, then the name of output in /software test result/Jupyter_testing_result/Juypter-2025.11.5 like this

2. Slurm script or general testing script 
		this script read the software test result dir and select the file that you want to check, 
		like "Which software do you want to check?"
		 (shows the directories 
			 1. vscode
			 2. Rstudio
			 3. pycharm
			 4. Jupyter
			 5. Blender
			    etc...)
		 (type the number in front of directories)
		 "which output files that you want to pick?"(sort it from newest oldest)
			 1.vscode-2025.11.5
			 2.vscode-2025.10.5
			 3.vscode-2025.9.5
			 (type number)
			 and it would have to show the 
			 linux version 
			 slurm version
			 loaded model
			 warewulf vesrion 
			 custom tools 
			   loaded modules
			   additional kernel 
			   which partition it used(node)
			   when and how long it took for the test script
			and save it to new directroy on General test that (if is not directory make it)
			 and show the combined output of these



   

Active software test outputs from OnDemand GUI applications (Jupyter, RStudio, VS Code, PyCharm, etc)
The automation collects metadata such as timestamps, node information, and software versions, then generates a consolidated report (General_test/) to document system readiness before cluster-wide deployment.

This validation framework improves reproducibility, ensures consistent software configurations across GUI and shell environments, and supports long-term maintainability for HPC users and administrators.

## Included Folder and Full Report

The repository now includes the full `Testing_Scripts/` folder and a comprehensive documentation report:

- Imported folder: `Testing_Scripts/`
- Full report: `Testing_Scripts/FULL_ENVIRONMENT_REPORT.md`

The report includes:

- environment snapshot and tool availability
- script settings and behavior notes
- folder structure summary
- original script inventory with descriptions
