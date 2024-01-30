#include <iostream>
#include <iomanip>

extern "C" {
    double divSimple(double, double);
    double divPrecedenceOrder(double, double, double);
    double divPrecedenceOrder2(double, double, double);
}

const std::string GREEN = "\033[1;32m";
const std::string RED = "\033[1;31m";
const std::string RESET = "\033[0m";

int main() {
    double v1, v2, v3;
    std::cout << "Give me 3 numbers separated by space: ";
    std::cin >> v1 >> v2 >> v3;
    std::cout << v1 << " " << v2 << " " << v3;
    auto actual = divSimple(v1, v2);
    auto expected = v1/v2;

    std::cout << std::endl;
    if (expected != actual) {
        std::cerr << RED << "Wrong answer for divSimple, expected: " << expected << ", actual: " << actual << std::endl << RESET;
        return 1;
    }

    actual = divPrecedenceOrder(v1, v2, v3);
    expected = v1+v2/v3*2.+v1;
    if (expected != actual) {
        std::cerr << RED << "Wrong answer for divPrecedenceOrder, expected: " << expected << ", actual: " << actual << std::endl << RESET;
        return 1;
    }

    actual = divPrecedenceOrder2(v1, v2, v3);
    expected = v1+v2*v3/2.+v1;
    if (expected != actual) {
        std::cerr << RED << "Wrong answer for divPrecedenceOrder2, expected: " << expected << ", actual: " << actual << std::endl << RESET;
        return 1;
    }

    std::cout << GREEN << "All tests passed!\n" << RESET;

    return 0;
}