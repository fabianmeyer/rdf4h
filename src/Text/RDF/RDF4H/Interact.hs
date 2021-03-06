-- |This module re-exports most of the other modules of this library and also
-- defines some convenience methods for interactive experimentation, such as
-- simplified functions for parsing and serializing RDF, etc.
--
-- All the load functions can be used with any 'RDF' implementation, so you
-- must declare a type in order to help the type system disambiguate the 
-- @RDF rdf@ constraint in those function's types.
-- 
-- Many of the simplified functions in this module call 'error' when there is 
-- a failure. This is so that you don't have to deal with 'Maybe' or 'Either'
-- return values while interacting. These functions are thus only intended
-- to be used when interactively exploring via ghci, and should not otherwise
-- be used.

module Text.RDF.RDF4H.Interact where

import qualified Data.Text as T

import Data.RDF.Types hiding (baseUrl)
import Data.RDF.Graph.TList()
import Data.RDF.Graph.AdjHashMap()

import Text.RDF.RDF4H.NTriplesParser
import Text.RDF.RDF4H.TurtleParser
import Text.RDF.RDF4H.NTriplesSerializer()
import Text.RDF.RDF4H.TurtleSerializer()

-- |Load a Turtle file from the filesystem using the optional base URL 
-- (used to resolve relative URI fragments) and optional document URI
-- (used to resolve <> in the document). 
-- 
-- This function calls 'error' with an error message if unable to load the file.
loadTurtleFile :: (Rdf a) => Maybe String -> Maybe String -> String -> IO (RDF a)
loadTurtleFile baseUrl docUri = _load parseFile (mkTurtleParser baseUrl docUri)

-- |Load a Turtle file from a URL just like 'loadTurtleFile' does from the local
-- filesystem. See that function for explanation of args, etc.
loadTurtleURL  :: (Rdf a) => Maybe String -> Maybe String -> String -> IO (RDF a)
loadTurtleURL baseUrl docUri  = _load parseURL (mkTurtleParser baseUrl docUri)

-- |Parse a Turtle document from the given 'T.Text' using the given @baseUrl@ and 
-- @docUri@, which have the same semantics as in the loadTurtle* functions.
parseTurtleString :: (Rdf a) => Maybe String -> Maybe String -> T.Text -> RDF a
parseTurtleString baseUrl docUri = _parse parseString (mkTurtleParser baseUrl docUri)

mkTurtleParser :: Maybe String -> Maybe String -> TurtleParser
mkTurtleParser b d = TurtleParser ((BaseUrl . T.pack) `fmap` b) (T.pack `fmap` d)

-- |Load an NTriples file from the filesystem.
-- 
-- This function calls 'error' with an error message if unable to load the file.
loadNTriplesFile :: (Rdf a) => String -> IO (RDF a)
loadNTriplesFile = _load parseFile NTriplesParser

-- |Load an NTriples file from a URL just like 'loadNTriplesFile' does from the local
-- filesystem. See that function for more info.
loadNTriplesURL :: (Rdf a) => String -> IO (RDF a)
loadNTriplesURL  = _load parseURL  NTriplesParser

-- |Parse an NTriples document from the given 'T.Text', as 'loadNTriplesFile' does
-- from a file.
parseNTriplesString :: (Rdf a) => T.Text -> RDF a
parseNTriplesString = _parse parseString NTriplesParser


-- |Print a list of triples to stdout; useful for debugging and interactive use.
printTriples :: Triples -> IO ()
printTriples  = mapM_ print

-- Load an RDF using the given parseFunc, parser, and the location (filesystem path
-- or HTTP URL), calling error with the 'ParseFailure' message if unable to load
-- or parse for any reason.
_load :: (Rdf a) => 
            (p -> String -> IO (Either ParseFailure (RDF a))) -> 
             p -> String -> IO (RDF a)
_load parseFunc parser location = parseFunc parser location >>= _handle

-- Use the given parseFunc and parser to parse the given 'T.Text', calling error
-- with the 'ParseFailure' message if unable to load or parse for any reason.
_parse :: (RdfParser p, Rdf a) => 
                        (p -> T.Text -> Either ParseFailure (RDF a)) -> 
                         p -> T.Text -> RDF a
_parse parseFunc parser rdfBs = either (error . show) id $ parseFunc parser rdfBs

-- Handle the result of an IO parse by returning the graph if parse was successful
-- and calling 'error' with the 'ParseFailure' error message if unsuccessful.
_handle :: (Rdf a) => Either ParseFailure (RDF a) -> IO (RDF a)
_handle = either (error . show) return
