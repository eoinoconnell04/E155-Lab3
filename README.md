# E155 Lab 3

This repo includes all my code for lab 3 of E155 Microprocessors: design and application.

The file `lab3_eo.sv` uses an FGPA to scan inputs from a keypad and display inputs on a 2 digit 7 segment display.

Some challenges addressed in this lab:
1. Dealing with assyncronus inputs (requires syncronizers)
2. Managing clock bounce
3. Protecting against corner case user inputs (multiple inputs at once, holding a button down before pressing others, etc.).
