from termcolor import cprint

from pkg.hello import say_hi


def greet():
    response = say_hi()
    return f"The CLI says, '{response}'"

if __name__ == "__main__":
   cprint(greet(), "yellow", attrs=["bold"])