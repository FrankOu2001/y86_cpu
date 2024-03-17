#!/usr/bin/python3
import argparse
import subprocess
import pathlib
from colorama import Fore

parser = argparse.ArgumentParser()
parser.add_argument("--yas", required="True", 
                    help="y86-64汇编器`yas`的绝对路径")
parser.add_argument("--yis", required="True", 
                    help="y86-64模拟器`yis`的绝对路径")
parser.add_argument("--cache", "-C", action='store_true', 
                    help="添加'-C' 测试pipe-predictor-cache,否则测试pipe-predictor")
args = parser.parse_args()

MEM_SIZE = 2048
TEST_CASE_TYPE = "*.ys"
SIMULATE_PATH = "./pipe-predictor"
if args.cache:
  TEST_CASE_TYPE = "cache" + TEST_CASE_TYPE
  SIMULATE_PATH += "-cache"

def main():
  code_path = pathlib.Path("test/test-code")
  files_path = sorted(list(code_path.glob(TEST_CASE_TYPE)), key=lambda x:x.name)
  for ys in files_path:
    print(f"{Fore.WHITE + ys.name}".ljust(36), end="")
    mem = [0 for x in range(0, MEM_SIZE)]
    yas = subprocess.Popen(f"./test/yas -V {ys.absolute()}", shell=True, stdout=subprocess.PIPE)
    yas.wait()
    for x in yas.stdout.readlines():
      y = x.decode().strip()
      # 不是赋值语句
      if y[0] == '/':
        continue
      (left, right) = (y.find('[')+1, y.find(']'))
      s = y.find("h")+1 # start of data
      index = int(y[left:right])
      data = int(y[s:-1], 16)
      mem[index] = data
    pass

    with open("input.txt", "w") as memFile:
      for x in mem:
        memFile.write(hex(x)[2:].zfill(2))
        memFile.write('\n')
      pass
    
    cpu = subprocess.Popen(f"cd {SIMULATE_PATH}/; make auto-test", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    yas = subprocess.Popen(f"{args.yas} {ys.absolute()}", shell=True, stdout=subprocess.PIPE)
    cpu.wait()
    yas.wait()
    yis = subprocess.Popen(f"{args.yis} {str(ys.absolute())[:-1]}o 65535", shell=True, stdout=subprocess.PIPE)
    yis.wait()
    with open(f"{SIMULATE_PATH}/output.txt", "rb") as outFile:
      xlines = outFile.readlines()
      ylines = yis.stdout.readlines()[1:]
      if len(xlines) != len(ylines):
        print(f"[{Fore.RED + 'FAIL'}]")
        return
      else:
        for x, y in zip(xlines, ylines):
          if x.strip() != y.strip():
            print(f"[{Fore.RED + 'FAIL'}]")
            return
    print(f"[{Fore.GREEN + 'PASS'}]")
    yas.kill()
    cpu.kill()
    yis.kill()
  pass

if __name__ == '__main__':
  main()