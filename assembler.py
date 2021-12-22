import difflib
import os
import sys
import webbrowser

OPCODE_SHIFT_LEFT_AMOUNT = 12
definedinstructions = {"ldi": 1, "inc": 7, "dec": 7, "mov": 7, "not": 7, "add": 7,
                       "sub": 7, "and": 7, "or": 7, "xor": 7, "ld": 2, "st": 3, "jmp": 5, "jz": 4,
                       "push": 10, "pop": 11, "call": 12, "ret": 13}
alucodes = {"inc": 58, "dec": 59, "mov": 57, "not": 56, "add": 0, "sub": 1, "and": 2, "or": 3, "xor": 4 }
instructions = []
variables = []
codeblocksize = 0
datablocksize = 0


class Variable:
    """This class represents a variable in the data section of the assembly code.

    name: str
        The name of the variable
    isarray: bool
        Whether the variable is a single variable, or an allocated array space
        for multiple variables.
    valueorsize: int
        The value of the variable if it's a single variable,
        or the size of the array if it's an array.
    address: int
        The address of the variable, has to be calculated after the code section
        has been read completely.
    size: int
        This is a computed value which always represents the size of the variable.
        It is the size of the array when the variable is an array, and 1 when
        the variable is just a variable.
    """

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
    """Represents an instruction.

    strop: str
        The string opcode of the instruction, such as "ldi".
    strargs: list[str]
        The instruction operands, tokenized, as a list of strings.
    strlabel: str
        The label of the instruction, None if the instruction has no label.
    args: list
        Will hold the numeric values of the operands, after converting numeric strings and labels.
    opcode: int
        The opcode number of the instruciton.
    address: int
        The address of the instruction. Initialized to the size of the code block at init.
    size: int
        The size of the instruction. The only 2 byte instruction is ldi, all the rest are 1.
    """

    def __init__(self, strop, strargs, strlabel=None):
        self.strop: str = strop
        self.strargs: list[str] = strargs
        self.args: list = []
        self.opcode: int = definedinstructions[strop]
        self.address: int = codeblocksize
        self.strlabel: str = strlabel
        if self.strop == "ldi":
            self.size = 2
        else:
            self.size = 1

    def __repr__(self) -> str:
        return (self.strlabel + ':' if self.strlabel else "") + " " + self.strop + " " + ' '.join(self.strargs)


def testoutput(filename: str, referencefilename: str, display=False):
    """Compares the differences between two machine code files.

    This function reads two compiled machine code files, one representing the code-generated code
    and one representing a correct output, and graphically shows where they differ in an HTML file.
    This function uses the difflib module.
    """

    referencefile = open(referencefilename, encoding="utf-8")
    referencecontent = referencefile.readlines()
    referencefile.close()

    sourcefile = open(filename, encoding="utf-8")
    sourcecontent = sourcefile.readlines()
    sourcefile.close()

    htmldiff = difflib.HtmlDiff()
    htmlname = filename + "-diff.html"
    with open(htmlname, "w", encoding="utf-8") as htmlfile:
        htmlfile.writelines(htmldiff.make_file(
            fromlines=referencecontent, tolines=sourcecontent, fromdesc="Reference", todesc="Program Output"))
    if display:
        webbrowser.open("file:///" + os.getcwd() + "/" + htmlname)
    if not all(map(lambda x, y: x == y, referencecontent, sourcecontent)):
        raise AssertionError("The generated output does not match the reference file.")

def twoscomplement(number: int):
    """Returns the 12-bit two's complement representation of a negative number.

    The returned integer is the 0-extended, 12-bit two's complement number. This function is used
    so that when OR'ing the operands with the opcode section, the 1 bits of negative numbers don't
    override the opcode section.
    """

    absolute = abs(number)
    absolutebinary = f'{absolute:0>12b}'
    invertedbinary = absolutebinary.replace('0', 'X').replace('1', '0').replace('X', '1')
    inverted = int(invertedbinary, 2)
    result = inverted + 1
    return result

def findlabelorvariable(label: str, sourceinstruction: Instruction):
    """
    This method is used to replace variable or jump labels
    with the corresponding values or jump offsets.

    label: str
        The string name of the label to search for.
    sourceinstruction: Instruction
        The instruction that contains the label as an operand. In the case that
        the label is a jump label, the offset is calculated using
        the address of this instruction.
    """

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
    """Returns either the value of the variable as a hex string,
    or n number of "0000" strings seperated by newlines, where n is the size of the array."""

    if variable.isarray:
        return (variable.size * (f'{0:0>4x}' + "\n")).strip()
    else:
        return f'{variable.valueorsize:0>4x}'

def gethexinstruction(instruction: Instruction):
    """Returns the machine code string for the instruction.

    instruction.args should be calculated before calling this method.
    """

    operation: str
    operation = instruction.strop
    args: list
    args = instruction.args

    # An instruction line consists of an opcode and any arguments.
    # Any addition should be made by bit-shifting the value,
    # and OR'ing with the existing instruction line.
    instructionline_1 = definedinstructions[operation] << OPCODE_SHIFT_LEFT_AMOUNT
    # This line is for 32-bit instructions only.
    instructionline_2 = 0
    if operation == "ldi" or operation == "pop":
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
    elif operation == "jmp" or operation == "jz" or operation == "call":
        #                                         x
        instructionline_1 = instructionline_1 | args[0]
    elif operation == "push":
        #                                               r
        instructionline_1 = instructionline_1 | (args[0] << 3)
    elif operation == "ret": # This line is needed to avoid exceptions.
        # d
        pass
    else:
        raise ValueError("Unkown operation " + operation +
                         " was passed to the method.")

    return f'{instructionline_1:0>4x}' + ("\n" + f'{instructionline_2:0>4x}' if operation == "ldi" else "")

def assemble(inputfilename: str, outfilename: str):
    """Reads from given text file inputfilename, and writes output to outfilename as machine code.

    Contents of outfilename are always overwritten.

    The function first reads through the entire source code, storing everything as-is.
    It then goes through all the variables, calculating the memory address for each variable.

    Afterwards, it generates numeric addresses for string labels and variables, using the addresses
    that were calculated earlier. While doing this, it also starts writing the instruction machine
    codes into a variable to print later.

    When the code section is done, the function adds the variables and arrays as hex strings to the
    same variable. Finally, the generated string is written to outfilename.
    """

    readingdata: bool = False
    readingcode: bool = False

    sourcefile = open(inputfilename, encoding="utf-8")
    sourcecontent = sourcefile.readlines()
    sourcefile.close()

    outcontent = ""

    # Read the .data and .code sections
    # (with all labels and variable names stored as strings in Python objects)
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
            elif len(tokenized) == 3 and tokenized[1] == ".space":
                # Reading a .space variable assignment
                variables.append(Variable(varname, True, int(tokenized[2], 0)))
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

    outfile = open(outfilename, "w", encoding="utf-8")
    outfile.write("v2.0 raw\n")
    outfile.write(outcontent)
    outfile.close()

# Program entrypoint is here.

if len(sys.argv) < 3:
    print("Please at least enter 1 input and 1 output file name.")
    exit(-1)

usrinfilename = sys.argv[1]
usroutfilename = sys.argv[2]
assemble(usrinfilename, usroutfilename)
