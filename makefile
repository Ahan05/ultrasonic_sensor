SRC = Ultrasonic.s
AVR = atmega32
AVR_ASP = m32


OBJ = $(SRC:.s=.o)
ELF = $(SRC:.s=.elf)
HEX = $(SRC:.s=.hex)

all: upload

hex: $(SRC)
	avr-as -mmcu=$(AVR) -o $(OBJ) $(SRC)
	avr-ld -o $(ELF) $(OBJ)
	avr-objcopy --output-target=ihex $(ELF) $(HEX)
upload:
	avrdude -c usbasp -p $(AVR_ASP) -U flash:w:$(HEX)

clean:
	rm -rf *.o *.hex *.elf

.PHONY: hex upload clean all
