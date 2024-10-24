{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
-- |
-- Module:      Data.OpenApi.Optics
-- Maintainer:  Andrzej Rybczak <andrzej@rybczak.net>
-- Stability:   experimental
--
-- Lenses and prisms for the <https://hackage.haskell.org/package/optics optics>
-- library.
--
-- >>> import Data.Aeson
-- >>> import Optics.Core
-- >>> :set -XOverloadedLabels
-- >>> import qualified Data.ByteString.Lazy.Char8 as BSL
-- >>> import qualified Data.HashMap.Strict.InsOrd as IOHM
--
-- Example from the "Data.OpenApi" module using @optics@:
--
-- >>> :{
-- BSL.putStrLn $ encodePretty $ (mempty :: OpenApi)
--   & #components % #schemas .~ IOHM.fromList [ ("User", mempty & #type ?~ OpenApiString) ]
--   & #paths .~
--     IOHM.fromList [ ("/user", mempty & #get ?~ (mempty
--         & at 200 ?~ ("OK" & #_Inline % #content % at "application/json" ?~ (mempty & #schema ?~ Ref (Reference "User")))
--         & at 404 ?~ "User info not found")) ]
-- :}
-- {
--     "components": {
--         "schemas": {
--             "User": {
--                 "type": "string"
--             }
--         }
--     },
--     "info": {
--         "title": "",
--         "version": ""
--     },
--     "openapi": "3.0.0",
--     "paths": {
--         "/user": {
--             "get": {
--                 "responses": {
--                     "200": {
--                         "content": {
--                             "application/json": {
--                                 "schema": {
--                                     "$ref": "#/components/schemas/User"
--                                 }
--                             }
--                         },
--                         "description": "OK"
--                     },
--                     "404": {
--                         "description": "User info not found"
--                     }
--                 }
--             }
--         }
--     }
-- }
--
-- For convenience optics are defined as /labels/. It means that field accessor
-- names can be overloaded for different types. One such common field is
-- @#description@. Many components of a Swagger specification can have
-- descriptions, and you can use the same name for them:
--
-- >>> BSL.putStrLn $ encodePretty $ (mempty :: Response) & #description .~ "No content"
-- {
--     "description": "No content"
-- }
-- >>> :{
-- BSL.putStrLn $ encodePretty $ (mempty :: Schema)
--   & #type        ?~ OpenApiBoolean
--   & #description ?~ "To be or not to be"
-- :}
-- {
--     "description": "To be or not to be",
--     "type": "boolean"
-- }
--
-- Additionally, to simplify working with @'Response'@, both @'Operation'@ and
-- @'Responses'@ have direct access to it via @'Optics.Core.At.at'@. Example:
--
-- >>> :{
-- BSL.putStrLn $ encodePretty $ (mempty :: Operation)
--   & at 404 ?~ "Not found"
-- :}
-- {
--     "responses": {
--         "404": {
--             "description": "Not found"
--         }
--     }
-- }
module Data.OpenApi.Optics () where

import Data.Aeson (Value)
import Data.Scientific (Scientific)
import Data.OpenApi.Internal
import Data.OpenApi.Internal.Utils
import Data.Text (Text)
import Optics.Core
import Optics.TH

-- Lenses

makeFieldLabels ''OpenApi
makeFieldLabels ''Components
makeFieldLabels ''Server
makeFieldLabels ''ServerVariable
makeFieldLabels ''RequestBody
makeFieldLabels ''MediaTypeObject
makeFieldLabels ''Info
makeFieldLabels ''Contact
makeFieldLabels ''License
makeFieldLabels ''PathItem
makeFieldLabels ''Tag
makeFieldLabels ''Operation
makeFieldLabels ''Param
makeFieldLabels ''Header
makeFieldLabels ''Schema
makeFieldLabels ''NamedSchema
makeFieldLabels ''Xml
makeFieldLabels ''Responses
makeFieldLabels ''Response
makeFieldLabels ''SecurityScheme
makeFieldLabels ''ApiKeyParams
makeFieldLabels ''OAuth2ImplicitFlow
makeFieldLabels ''OAuth2PasswordFlow
makeFieldLabels ''OAuth2ClientCredentialsFlow
makeFieldLabels ''OAuth2AuthorizationCodeFlow
makeFieldLabels ''OAuth2Flow
makeFieldLabels ''OAuth2Flows
makeFieldLabels ''ExternalDocs
makeFieldLabels ''Encoding
makeFieldLabels ''Example
makeFieldLabels ''Discriminator
makeFieldLabels ''Link

-- Prisms

makePrismLabels ''SecuritySchemeType
makePrismLabels ''Referenced

-- OpenApiItems prisms

instance
  ( a ~ [Referenced Schema]
  , b ~ [Referenced Schema]
  ) => LabelOptic "_OpenApiItemsArray"
         A_Review
         OpenApiItems
         OpenApiItems
         a
         b where
  labelOptic = unto (\x -> OpenApiItemsArray x)
  {-# INLINE labelOptic #-}

instance
  ( a ~ Referenced Schema
  , b ~ Referenced Schema
  ) => LabelOptic "_OpenApiItemsObject"
         A_Review
         OpenApiItems
         OpenApiItems
         a
         b where
  labelOptic = unto (\x -> OpenApiItemsObject x)
  {-# INLINE labelOptic #-}

-- =============================================================
-- More helpful instances for easier access to schema properties

type instance Index Responses = HttpStatusCode
type instance Index Operation = HttpStatusCode

type instance IxValue Responses = Referenced Response
type instance IxValue Operation = Referenced Response

instance Ixed Responses where
  ix n = #responses % ix n
  {-# INLINE ix #-}
instance At   Responses where
  at n = #responses % at n
  {-# INLINE at #-}

instance Ixed Operation where
  ix n = #responses % ix n
  {-# INLINE ix #-}
instance At   Operation where
  at n = #responses % at n
  {-# INLINE at #-}

-- #type

instance
  ( a ~ Maybe OpenApiType
  , b ~ Maybe OpenApiType
  ) => LabelOptic "type" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #type
  {-# INLINE labelOptic #-}

-- #default

instance
  ( a ~ Maybe Value, b ~ Maybe Value
  ) => LabelOptic "default" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #default
  {-# INLINE labelOptic #-}

-- #format

instance
  ( a ~ Maybe Format, b ~ Maybe Format
  ) => LabelOptic "format" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #format
  {-# INLINE labelOptic #-}

-- #items

instance
  ( a ~ Maybe OpenApiItems
  , b ~ Maybe OpenApiItems
  ) => LabelOptic "items" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #items
  {-# INLINE labelOptic #-}

-- #maximum

instance
  ( a ~ Maybe Scientific, b ~ Maybe Scientific
  ) => LabelOptic "maximum" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #maximum
  {-# INLINE labelOptic #-}

-- #exclusiveMaximum

instance
  ( a ~ Maybe Bool, b ~ Maybe Bool
  ) => LabelOptic "exclusiveMaximum" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #exclusiveMaximum
  {-# INLINE labelOptic #-}

-- #minimum

instance
  ( a ~ Maybe Scientific, b ~ Maybe Scientific
  ) => LabelOptic "minimum" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #minimum
  {-# INLINE labelOptic #-}

-- #exclusiveMinimum

instance
  ( a ~ Maybe Bool, b ~ Maybe Bool
  ) => LabelOptic "exclusiveMinimum" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #exclusiveMinimum
  {-# INLINE labelOptic #-}

-- #maxLength

instance
  ( a ~ Maybe Integer, b ~ Maybe Integer
  ) => LabelOptic "maxLength" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #maxLength
  {-# INLINE labelOptic #-}

-- #minLength

instance
  ( a ~ Maybe Integer, b ~ Maybe Integer
  ) => LabelOptic "minLength" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #minLength
  {-# INLINE labelOptic #-}

-- #pattern

instance
  ( a ~ Maybe Text, b ~ Maybe Text
  ) => LabelOptic "pattern" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #pattern
  {-# INLINE labelOptic #-}

-- #maxItems

instance
  ( a ~ Maybe Integer, b ~ Maybe Integer
  ) => LabelOptic "maxItems" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #maxItems
  {-# INLINE labelOptic #-}

-- #minItems

instance
  ( a ~ Maybe Integer, b ~ Maybe Integer
  ) => LabelOptic "minItems" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #minItems
  {-# INLINE labelOptic #-}

-- #uniqueItems

instance
  ( a ~ Maybe Bool, b ~ Maybe Bool
  ) => LabelOptic "uniqueItems" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #uniqueItems
  {-# INLINE labelOptic #-}

-- #enum

instance
  ( a ~ Maybe [Value], b ~ Maybe [Value]
  ) => LabelOptic "enum" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #enum
  {-# INLINE labelOptic #-}

-- #multipleOf

instance
  ( a ~ Maybe Scientific, b ~ Maybe Scientific
  ) => LabelOptic "multipleOf" A_Lens NamedSchema NamedSchema a b where
  labelOptic = #schema % #multipleOf
  {-# INLINE labelOptic #-}
