package main

import (
	flags "github.com/jessevdk/go-flags"
	"io"
	"os"
)

type FlagOptions struct {
	OutputFilename         string `short:"o" long:"output" value-name:"OUTPUT_FILE" description:"Output filename (default: stdout)"`
	OutputDerFormat        bool   `short:"d" long:"der" description:"Output DER format"`
	OutputIntermediateOnly bool   `short:"i" long:"intermediate-only" description:"Output intermediate certificates only"`
	Args                   struct {
		InputFilename  string `positional-arg-name:"INPUT_FILE" description:"Input filename (default: stdin)"`
		OutputFilename string `positional-arg-name:"OUTPUT_FILE" description:"Output filename (deprecated, use -o option instead)"`
	} `positional-args:"yes"`
}

type Options struct {
	InputReader            io.Reader
	OutputWriter           io.Writer
	OutputDerFormat        bool
	OutputIntermediateOnly bool
}

func GetOptions() (*Options, error) {
	var (
		flagOptions FlagOptions
		options     Options
		err         error
	)

	flagsParser := flags.NewParser(&flagOptions, flags.HelpFlag|flags.PassDoubleDash)
	_, err = flagsParser.Parse()
	if err != nil {
		return nil, err
	}

	if flagOptions.Args.InputFilename != "" {
		options.InputReader, err = os.Open(flagOptions.Args.InputFilename)
		if err != nil {
			return nil, err
		}
	} else {
		options.InputReader = os.Stdin
	}

	if flagOptions.OutputFilename != "" {
		options.OutputWriter, err = os.Create(flagOptions.OutputFilename)
		if err != nil {
			return nil, err
		}
	} else if flagOptions.Args.OutputFilename != "" {
		// deprecated, TODO: remove
		options.OutputWriter, err = os.Create(flagOptions.Args.OutputFilename)
		if err != nil {
			return nil, err
		}
	} else {
		options.OutputWriter = os.Stdout
	}

	options.OutputDerFormat = flagOptions.OutputDerFormat
	options.OutputIntermediateOnly = flagOptions.OutputIntermediateOnly

	return &options, nil
}
