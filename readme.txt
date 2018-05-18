
---++ ParaEngine README 

Last Updated: 2006-12-12

INTRODUCTION 

Refer to this document if you encounter difficulties with one or more 
aspects of installation or running the Demo of Kids Movie Creator. 
Many of the most commonly encountered issues are covered here. 

If you experience any problems please make sure that you have the 
latest drivers for you PC installed.

www.microsoft.com/directx/
www.nvidia.com
www.ati.com

Please be aware, this software is a demo and is not representative of 
the final product, product features are subject to change and 
revision without notice. The software wherein is incomplete and is 
provided with no warranty of any kind.

_____________________________________________________________________

MINIMUM SYSTEM REQUIREMENTS

- 	English version of Microsoft Windows 2000/XP 

- 	Celeron 1.5GHz Pentium 4(1500MHz) or equivalent AMD	processor.

-	512MB RAM 

-	100MB of uncompressed free hard disk space 

-	100% DirectX 9.0c compatible 16-bit sound card and latest drivers 

-	100% Windows 2000/XP compatible mouse, keyboard and latest drivers 

-	DirectX 9.0c

-	128MB Hardware Accelerated video card with Shader 1 support 
	and the latest drivers.  Must be 100% DirectX 9.0c 
	compatible.  Nvidia GeForce 4 Ti 4400 or ATI Radeon 9800 
	are the	recommended minimum hardware.

-	Monitor must be able to display 1024x768 resolution or above.

* Important Note: Some cards with the chipsets listed 
here may not be compatible with the 3D acceleration features 
Please refer to your hardware manufacturer for 100% DirectX 9.0c compatibility.

______________________________________________________________________ 

INSTALLATION & SET UP ISSUES 

DirectX Installation 

You can install the latest version of DirectX by going to 
http://www.microsoft.com/windows/directx and downloading the latest 
version available. 

______________________________________________________________________ 

VIDEO ISSUES 

Monitor Display 

Should you find you have set the resolution and cannot run the demo, in order to reset 
the resolution open the config/config.txt file found in the installation directory 
in a text editor. Change the lines according to instructions in the file

______________________________________________________________________ 

GAMEPLAY ISSUES 

Tutorial Advice 

Click on a tutorial character repeatedly will cycle through text that it has to say.

______________________________________________________________________ 

WINDOWS SPECIFIC OPERATING SYSTEM ISSUES 

Windows 2000/XP

If you are running Windows 2000 or Windows XP, you must have 
Administrator rights to properly install and play the demo. 

Windows Vista

You need to open write access of your windows account to the game install directory, 
even you are an administrator. Alternatively, one needs to disable UAC(User access control) 
in Windows Vista.


---+++ Controls

- character movement: W,A,S,D,Q,E,R,SPACE, left/right mouse drag
- mount or toggle to closest character: left-shift
- click on the closest character: left or right control key
- character cycle: O (letter, not numerical number)
- chat or speak: Enter key.
- camera: 
	- C: change to free camera mode
		in free camera mode: use mouse wheel to adjust camera movement speed.
	- F: change to follow camera mode
	- +: lift up camera 
	- -: lower down camera 
	- Insert: camera zoom in
	- Delete: camera zoom out
- pause game: P
- Go to last step: ESC
- In-Game Help: F1
- change device: F2
- GUI inspection: F3
- ParaIDE editor: F5
- Show/Hide GUI: F8
- take screen shot: F11 (files are saved at /screen shots/)
- AVI recording resume/suspend: F9
- Left mouse to click on GUI objects
- GUI: left mouse, left mouse drag.
- character animation cycle: 9, 0 on main keyboard


---+++ Command line
the following command line is supported. 
| single="true" | whether only one instance of the game is allowed.|
| fullscreen="true" | whether start as fullscreen |
| d3d="false" | whether start without graphics |
| bootstrapper="config/bootstrapper.xml" | which bootstrapper file to use at startup|

---+++ Function list

- multiple scene construction
- Ocean, Terrain, Sky modification and texturing
- Character and creature creation
- Animation and movie composing.
- AVI movie exporting
- Scene preservation
- AI behaviors:
	1. talk character: first let the character speak something by pressing the Enter key, and then assign talk behavior to it. The character will repeat its last speech when clicked. 
		when entering text, the following format is supported. 
		"\t tutorial_category_name" : the character will speak according to predefined templates at script/AI/templates/Tutorial*.txt
		"[\?] {sentence \n}": optionally display a ? mark on the character head when it is loaded. Speak one sentence on each mouse click. sentences are separated by "\n"
		"[\!] {sentence \n}": optionally display a ! mark on the character head when it is loaded. Speak one sentence on each mouse click. sentences are separated by "\n"
		e.g."\t intro", "hello!", "\? Hi there\nTalk to LXZ\nGood Luck!\n", "\!help me please.\nbuild me a house\n"
	 Note: The content of each sentence can contain XML style makeups.The following are supported makeups
		<video>file name</video> it will play a given video in the tutorial video player box. e.g. "See video<video>video/tutorial1.wmv</video> for how to act."	
	2. random walk character: 
	3. follower character: 
	4. shopkeeper character: 

---+++ HOW to submit crash report to developers?

Every time the game crashes, it will generate a file called *.dmp under the installation directory. There will also be a file called log.txt under the same directory.
Please put these two files in a zip package and send us by email to support@kids3dmovie.com. One can also use our forum's technical support section for direct report of the error.


---+++ HOW to submit test report to us?

If the game does not run properly or runs very slow, please post the following information directly on our forum www.kids3dmovie.com/forum/ or send by email to support@kids3dmovie.com
- A description of the shortest steps to reproduce the problem from the beginning of a clean installation of the game.
- log.txt file under the application directory
- Follow A.1 to generate DXDIAG report txt file containing your graphics card specifications
- if the problem causes a crash, send the latest dump file under the application directory


---+++ A.1: Generating DXDIAG report file

Use the following procedure to create and save a DXDIAG report to include with support requests.
- From your Windows "Start" button, select "Run..."
- Type DXDIAG in the "Open:" field and hit Enter.
- DXDIAG will start, and may display a prompt that begins "Do you want to allow DxDiag to check if your drivers are digitally signed..." Answer "Yes" to this query if it appears.
- A window entitled "DirectX Diagnostic Tool" appears, and in the lower left corner, a progress meter begins to advance towards the right as DXDIAG collects information relating to the system's hardware and Windows component configuration.
- When the progress indicator disappears, hit the "Save All Information" button. Save this file as DXDIAG.TXT where it can be easily located. By default, DXDIAG will place this file on the Desktop.
Note: If you do not see a button that allows you to save the output, you will need to log on to Windows as the Administrator.

______________________________________________________________________ 

LEGAL INFORMATION 
______________________________________________________________________ 

ParaEngine uses PhysX from Ageia for physics.ParaEngine and NPL are 
trademarks of ParaEngine Tech Studio in China. All other brand names 
are trademarks of their respective owners.
For more information, please see copyright.txt