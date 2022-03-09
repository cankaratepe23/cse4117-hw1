# CSE4117 Microprocessors Projects
## Description

This repository was made public on 09/03/2022.

This repository contains all the work we did for the three projects assigned to us as part of the CSE4117 Microprocessors course at Marmara University.

The main focus of each project was to implement a CPU design, which was covered in course lectures, in the Logisim circuit simulation software and on a Cyclone IV FPGA using Verilog. The project assignments also included writing assembly code to accomplish some task and implementing an assembler to go along with it, which was given in an incomplete state and written in C. We chose to write our own assembler from scratch in Python, which in the end ended up being a great decision to make early on.

The PDF files describing each project will be added later.

## Project Structure or the Explanation of Files and Directories

Since the three projects were developed incrementally, this repository does not contain different files for different versions of the files. Instead, checkout a specific commit/tag to view history of our work.

For example, you can checkout to the v2.0.0 tag to view the repository in its final state before the submission of the second project.

Since we did not try to keep history as seperate files, there is no clear way to determine which pieces of code were given to us pre-written. You can check [the course website](https://marmaralectures.com) as most of the pre-written code was distributed from that website, but its content is prone to change.


### **Project Description PDFs**
Contains the project assignment PDFs which describe the requirements of the projects, submission instructions, deadlines etc.

### **cpu-verilog**
Contains the verilog code (some pre-written, some implemented ourselves)
for the FPGA parts of the projects.

### **Microcode Generator.xlsx**
A handy Excel worksheet originally made by Rıdvan San and changed to fit our specific needs and CPU structure. This is used to easily convert control signals to their hex representations to quickly copy into a ROM module in our control unit.

### **assembler.c**
The pre-written and incomplete assembler that was given to us to complete and use in our project. We instead decided write our assembler from scratch and use `assembler.py` instead.

### **assembler.py**
The assembler for our CPU designs, with rich features such as the ability to compare compiled machine code with a reference code, error checking and clear error messages. Writing our assembler from scratch has sped up our development by at least %1500. You can find some explanatory comments in the source code.

## Contributors
- Can Karatepe - 150118004
- Eymen Topçuoğlu - 150117009
- Fatih Emin Öge - 150118034

