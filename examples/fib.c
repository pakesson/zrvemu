int main();
int fib(int n);

void _start()
{
    main();
    while (1);
}

int main()
{
    return fib(10);
}

int fib(int n)
{
    if (n == 0 || n == 1)
    {
        return n;
    }
    else
    {
        return fib(n-1) + fib(n-2);
    }
}