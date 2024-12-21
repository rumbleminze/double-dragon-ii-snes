package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)

// This utility will take an NES rom as input, and split it up into 4k banks
// It currently assumes a lot about the game, and is set up to parse the game
// Super Dodge Ball, a MMC1 game, where banks 8+ are CHR ROM banks and within those banks
// banks at memory 1A000 - 1FFFF are data and 8000 - 19FFF are tiles.  It will automatically
// convert the 2bpp tiles into 4bpp SNES format, but leave the data parts as is.
//
// For all banks it'll break up and label every 0x100 bytes, as well as setting a segment directive
//
// This script also assumes that the file will have a 16 byte header that we skip.
//
// It very naively will just print out the code as:
//
// .byte $HL, $HL, ......
//
// with 16 bytes per line
//
// Double Dragon II code is split up into the following way:
// 00000 - 1FFFF - (banks 0 - 7) PRG ROM, technically we should splite these into 2KB instead of 4KB as that's
// 				     how MMC3 deals with things.  the last 4 KB is fixed in place.
//				     if we wanted to approach MMC3 the same way we dealth with MMC1,
// 					 we'd need to keep every pair of banks 0 - D
// 				     that'd be 182 combinations :eek:
// 				     we'll need to do something else.
//				     there's also a few places that are tiles within here
//
// CHROM Banks are
//  0000 - 0FFFF - BG Tiles, always loaded in 4KB banks
// 10000 - 107FF - Player Sprite Tiles, always loaded in the first bank of sprites
// 10800 - Roper
//
// 11000 - Linda
// 11800 - Abobo

// 12000 - Burnov dying
// 12800 - Shadow you

// 13000 - Chin
// 13800 - William

// 14000 - Burnov fighting
// 14800 - Abore

// 15000 - Right Arm
// 15800 - Ninja

// 16000 - Mysterious warrior
// 16800 - between fight sprites

// 17000 - more BG tiles, for title screen

// 18000 - more mysterious warrior tiles
// 18800 - more Burnov tiles

// 19000 - more Roper tiles (Roper w/Dynamite?)
// 19800 - 1CFFF - cutscene tiles

// 1D000 - end - Data

func main() {
	inputFile := flag.String("in", "Double Dragon II - The Revenge (U).nes", "input file to split out")

	inputBytes, _ := ioutil.ReadFile(*inputFile)
	var banks [][]byte
	var bankSize = 0x4000

	// remove the header
	headerLess := inputBytes[0x10:]

	for i := 0; i < len(headerLess); i += bankSize {
		end := i + bankSize

		if end > len(headerLess) {
			end = len(headerLess)
		}

		banks = append(banks, headerLess[i:end])
	}
	var byteOffset = 0x8000
	for i := 0; i < 8; i++ {
		if i == 7 {
			byteOffset = 0xC000
		}

		var bankFile, _ = os.Create(fmt.Sprintf("bank%d.asm", i))
		defer bankFile.Close()
		if i != 7 {
			bankFile.WriteString(fmt.Sprintf(".segment \"PRGA%d\"", i+1))
		}
		bankFile.WriteString(fmt.Sprintf("; Bank %d\n", i))
		for byteIndex := 0; byteIndex < len(banks[i]); byteIndex++ {
			if byteIndex <= 0x1FFFF {
				if byteIndex%0x100 == 0 {
					bankFile.WriteString(fmt.Sprintf("\n\n; %04X - bank %d\n", byteIndex+byteOffset, i))
				}
				if byteIndex%0x10 == 0 {
					bankFile.WriteString(".byte ")
				}

				bankFile.WriteString(fmt.Sprintf("$%02X", banks[i][byteIndex]))

				if byteIndex%0x10 == 0x0F {
					bankFile.WriteString("\n")
				} else {
					bankFile.WriteString(", ")
				}
			}
		}
		if i != 7 {
			bankFile.WriteString(fmt.Sprintf(
				".segment \"PRGA%dC\"\nfixeda%d:\n.include \"bank7.asm\"\nfixeda%d_end:",
				i+1, i+1, i+1,
			))
		}
	}
	// CHR banks
	tileset := 0
	for i := 8; i < 16; i++ {
		var bankFile, _ = os.Create(fmt.Sprintf("chrom-tiles-%d.asm", i-8))
		defer bankFile.Close()
		bankFile.WriteString(fmt.Sprintf(".segment \"PRGA%X\"\n", i))
		for byteIndex := 0; byteIndex < len(banks[i]); byteIndex += 0x10 {
			if byteIndex%0x1000 == 0 {
				bankFile.WriteString(fmt.Sprintf("chrom_bank_%d_tileset_%d:\n", i-8, tileset))
				tileset++
			}

			if i < 15 || (byteIndex < 0x1000 && i == 15) {
				// converts these to SNES expected format
				bankFile.WriteString(
					fmt.Sprintf(
						".byte $%02X, $%02X, $%02X, $%02X, $%02X, $%02X, $%02X, $%02X, $%02X,"+
							" $%02X, $%02X, $%02X, $%02X, $%02X, $%02X, $%02X\n",
						banks[i][byteIndex],
						banks[i][byteIndex+8],
						banks[i][byteIndex+1],
						banks[i][byteIndex+1+8],
						banks[i][byteIndex+2],
						banks[i][byteIndex+2+8],
						banks[i][byteIndex+3],
						banks[i][byteIndex+3+8],
						banks[i][byteIndex+4],
						banks[i][byteIndex+4+8],
						banks[i][byteIndex+5],
						banks[i][byteIndex+5+8],
						banks[i][byteIndex+6],
						banks[i][byteIndex+6+8],
						banks[i][byteIndex+7],
						banks[i][byteIndex+7+8],
					),
				)
				bankFile.WriteString(".byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00\n")
				// If some of the banks in the PRG rom are actually data banks, then we need to _not_ format them at 4bpp.
				// for Double Dragon II is is $1D000 - $1FFFF, i.e. the last 0x3000 bytes of bank 16.
			} else {
				// these are data banks that need to be formatted differently
				bankFile.WriteString(
					fmt.Sprintf(
						".byte $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00\n"+
							".byte $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00, $%02X, $00\n",
						banks[i][byteIndex],
						banks[i][byteIndex+1],
						banks[i][byteIndex+2],
						banks[i][byteIndex+3],
						banks[i][byteIndex+4],
						banks[i][byteIndex+5],
						banks[i][byteIndex+6],
						banks[i][byteIndex+7],
						banks[i][byteIndex+8],
						banks[i][byteIndex+9],
						banks[i][byteIndex+10],
						banks[i][byteIndex+11],
						banks[i][byteIndex+12],
						banks[i][byteIndex+13],
						banks[i][byteIndex+14],
						banks[i][byteIndex+15],
					),
				)
			}
		}
	}

}
