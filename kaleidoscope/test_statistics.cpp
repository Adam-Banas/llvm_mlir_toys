#include <iostream>
#include <iomanip>

extern "C" {
    double mean(double, double);
    double mean4(double, double, double, double);
}

const std::string GREEN = "\033[1;32m";
const std::string RED = "\033[1;31m";
const std::string RESET = "\033[0m";

int main() {
    double v1, v2;
    std::cout << "Give me 2 numbers separated by space: ";
    std::cin >> v1 >> v2;
    auto v3=5.0, v4=6.0;
    auto answer2 = mean(v1, v2);
    auto answer4 = mean4(v1, v2, v3, v4);
    std::cout << std::fixed << std::setprecision(1) << "\nAverage of " << v1 << " and " << v2 << ": " << std::setprecision(2) << answer2 << std::endl;
    std::cout << std::setprecision(1) << "Average of " << v1 << ", " << v2 << ", " << v3 << ", " << v4 << ": " << std::setprecision(2) << answer4 << std::endl;

    std::cout << std::endl;

    auto correct2 = (v1+v2)/2;
    if (correct2 != answer2) {
        std::cerr << RED << "Wrong answer for average of two numbers, expected: " << correct2 << ", actual: " << answer2 << std::endl << RESET;
        return 1;
    }

    auto correct4 = (v1+v2+v3+v4)/4;
    if (correct4 != answer4) {
        std::cerr << RED << "Wrong answer for average of four numbers, expected: " << correct4 << ", actual: " << answer4 << std::endl << RESET;
        return 1;
    }

    std::cout << GREEN << "All tests passed!\n" << RESET;

    return 0;
}