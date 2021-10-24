import os
import argparse


def dict_iterator(input, key):
    try:
        val = input[key]
    except Exception as e:
        print(e)
        val = None
    return val


def main(data, keyinput):
    if "/" in keyinput:
        keyinput = keyinput.split('/')
    else:
        keyinput = keyinput.split()
    print("Keys:" + str(keyinput))
    keyInp = True
    if not isinstance(data, dict):
        print("Provided is not a nested JSON")
    while keyInp is True:
        if isinstance(data, dict):
            for i in range(len(keyinput)):
                data = dict_iterator(data, keyinput[i])
                if data is None:
                    data = "ERROR:key is not matching with json object"
                if i == 0:
                    keyInp = False
        else:
            keyInp = False
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Please pass Nested Objects')
    parser.add_argument('-d', action='store', type=str, dest='object',
                        help='''please pass as "{'a':{'b':{'c':'d'}}}" ''', required=True)
    parser.add_argument('-k', action='store', type=str, dest='keyinput',
                        help='''please pass as "a/b/c/" or "x" ''', required=True)
    options = parser.parse_args()
    dataVal = eval(options.object)
    keyVal = options.keyinput
    keyResult = main(dataVal, keyVal)
    print("Values:"+ str(keyResult))
