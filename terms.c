#include <math.h>
#include <stdio.h>

int main() {
    int terms = 7; // reg1
    int sum = 0; // reg0
    int negtwo = -2; // reg7
    for (terms; terms > 0; terms+=negtwo) { 
        int squared = 0; // reg2
        int j = terms; // reg3
        for (j; j > 0; j--) {
            squared += terms;
        }
        sum += squared;
    }
    printf("%d", sum);
}