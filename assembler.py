import difflib
import os
import sys
import webbrowser

opcodeshiftleftamount = 12
definedinstructions = {"ldi": 1, "inc": 7, "dec": 7, "mov": 7, "not": 7, "add": 7,
                       "sub": 7, "and": 7, "or": 7, "xor": 7, "ld": 2, "st": 3, "jmp": 5, "jz": 4}
alucodes = {"inc": 58, "dec": 59, "mov": 57, "not": 56, "add": 0, "sub": 1, "and": 2, "or": 3, "xor": 4, }
instructions = []
variables = []
codeblocksize = 0
datablocksize = 0


class Variable:
    def __init__(self, name, isarray, valueorsize):
        self.name: str = name
        self.isarray: bool = isarray
        self.valueorsize: int = valueorsize
        self.address = 0
        if self.isarray:
            self.size = self.valueorsize
        else:
            self.size = 1
    def __repr__(self) -> str:
        return self.name + " " + (".space" if self.isarray else "") + " " + self.valueorsize


class Instruction:
    def __init__(self, strop, strargs, strlabel=None):
        self.strop = strop
        self.strargs = strargs
        self.args = []
        self.opcode = definedinstructions[strop]
        self.address = codeblocksize
        self.strlabel = strlabel
        if self.strop == "ldi":
            self.size = 2
        else:
            self.size = 1

    def __repr__(self) -> str:
        return (self.strlabel + ':' if self.strlabel else "") + " " + self.strop + " " + ' '.join(self.strargs)


def testoutput(filename: str, referencefilename: str, display=False):
    referencefile = open(referencefilename)
    referencecontent = referencefile.readlines()
    referencefile.close()

    sourcefile = open(filename)
    sourcecontent = sourcefile.readlines()
    sourcefile.close()

    htmldiff = difflib.HtmlDiff()
    htmlname = filename + "-diff.html"
    with open(htmlname, "w") as htmlfile:
        htmlfile.writelines(htmldiff.make_file(
            fromlines=referencecontent, tolines=sourcecontent, fromdesc="Reference", todesc="Program Output"))
    if display:
        webbrowser.open("file:///" + os.getcwd() + "/" + htmlname)
    if not all(map(lambda x, y: x == y, referencecontent, sourcecontent)):
        raise AssertionError("The generated output does not match the reference file.")

def twoscomplement(number: int):
    absolute = abs(number)
    absolutebinary = f'{absolute:0>12b}'
    invertedbinary = absolutebinary.replace('0', 'X').replace('1', '0').replace('X', '1')
    inverted = int(invertedbinary, 2)
    result = inverted + 1
    return result

def findlabelorvariable(label: str, sourceinstruction: Instruction):
    instruction: Instruction
    for instruction in instructions:
        if instruction.strlabel and instruction.strlabel == label:
            reloffset = instruction.address - sourceinstruction.address - 1
            if reloffset >= 0:
                return reloffset
            else:
                return twoscomplement(reloffset)
    variable: Variable
    for variable in variables:
        if variable.name == label:
            return variable.address

    raise KeyError("Label " + label + " does not reference anything.")

def gethexvariable(variable: Variable):
    if variable.isarray:
        return (variable.size * (f'{0:0>4x}' + "\n")).strip()
    else:
        return f'{variable.valueorsize:0>4x}'

def gethexinstruction(instruction: Instruction):
    operation: str
    operation = instruction.strop
    args: list
    args = instruction.args

    # An instruction line consists of an opcode and any arguments.
    # Any addition should be made by bit-shifting the value, and OR'ing with the existing instruction line.
    instructionline_1 = definedinstructions[operation] << opcodeshiftleftamount
    # This line is for 32-bit instructions only.
    instructionline_2 = 0
    if operation == "ldi":
        #                                         r
        instructionline_1 = instructionline_1 | args[0]
        #                     x
        instructionline_2 = args[1]
    elif operation == "inc" or operation == "dec":
        #                                                ALU CODE                    r1         r1
        instructionline_1 = instructionline_1 | (alucodes[operation] << 6) | (args[0] << 3) | args[0]
    elif operation == "mov" or operation == "not":
        #                                                ALU CODE                    r2         r1
        instructionline_1 = instructionline_1 | (alucodes[operation] << 6) | (args[1] << 3) | args[0]
    elif operation == "add" or operation == "sub" or operation == "and" or operation == "xor":
        #                                                ALU CODE                    r2             r3           r1
        instructionline_1 = instructionline_1 | (alucodes[operation] << 9) | (args[1] << 6) | (args[2] << 3) | args[0]
    elif operation == "ld":
        #                                               r2          r1
        instructionline_1 = instructionline_1 | (args[1] << 3) | args[0]
    elif operation == "st":
        #                                               r2              r1
        instructionline_1 = instructionline_1 | (args[1] << 6) | (args[0] << 3)
    elif operation == "jmp" or operation == "jz":
        #                                         x
        instructionline_1 = instructionline_1 | args[0]
    else:
        raise ValueError("Unkown operation " + operation +
                         " was passed to the method.")
    
    return f'{instructionline_1:0>4x}' + ("\n" + f'{instructionline_2:0>4x}' if operation == "ldi" else "")

def assemble(inputfilename: str, outfilename: str):
    readingdata: bool = False
    readingcode: bool = False

    sourcefile = open(inputfilename)
    sourcecontent = sourcefile.readlines()
    sourcefile.close()

    outcontent = ""

    # Read the .data and .code sections (with all labels and variable names stored as strings) in Python objects
    for srcline in sourcecontent:
        line = srcline
        if "//" in line:
            line = srcline.split("//")[0]
        if line.isspace():
            continue

        haslabel: bool = False
        tokenized = line.split()

        if tokenized[0] == ".data":
            readingdata = True
            readingcode = False
            continue
        elif tokenized[0] == ".code":
            readingdata = False
            readingcode = True
            continue
        elif tokenized[0] not in definedinstructions:
            # Reading a label
            haslabel = True

        if readingdata:
            varname = tokenized[0][:-1]
            if len(tokenized) == 2:
                # Reading a single variable assignment
                variables.append(
                    Variable(varname, False, int(tokenized[1], 0)))
                pass
            elif len(tokenized) == 3 and tokenized[1] == ".space":
                # Reading a .space variable assignment
                variables.append(Variable(varname, True, int(tokenized[2], 0)))
                pass
        elif readingcode:
            if haslabel:
                instructions.append(Instruction(tokenized[1], tokenized[2:], tokenized[0]))
            else:
                instructions.append(Instruction(tokenized[0], tokenized[1:]))
            global codeblocksize
            codeblocksize = codeblocksize + instructions[-1].size
    
    # Generate addresses for variables.
    variable: Variable
    for variable in variables:
        global datablocksize
        variable.address = codeblocksize + datablocksize
        datablocksize = datablocksize + variable.size

    # Generate numeric addresses for the labels and variables in the instructions.
    # Put hex representations of the instructions to a string.
    instruction: Instruction
    for instruction in instructions:
        instruction.args = [(int(arg, 0) if arg.isdigit() or arg.startswith("0x") else findlabelorvariable(arg, instruction)) for arg in instruction.strargs]
        outcontent = outcontent + gethexinstruction(instruction) + "\n"

    # Put hex representations of the variables to the string.
    for variable in variables:
        outcontent = outcontent + gethexvariable(variable) + "\n"

    outfile = open(outfilename, "w")
    outfile.write("v2.0 raw\n")
    outfile.write(outcontent)
    outfile.close()

if len(sys.argv) < 3:
    print("Please at least enter 1 input and 1 output file name.")
    exit(-1)

infilename = sys.argv[1]
outfilename = sys.argv[2]
assemble(infilename, outfilename)
