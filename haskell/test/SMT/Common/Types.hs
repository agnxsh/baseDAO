-- SPDX-FileCopyrightText: 2021 TQ Tezos
-- SPDX-License-Identifier: LicenseRef-MIT-TQ

module SMT.Common.Types () where
--   ( ModelInputArg (..)
--   , ModelInput (..)
--   , MkModelInput
--   , MkGenPropose
--   , MkGenCustomCalls
--   , SmtOption (..)
--
--   , GeneratorState (..)
--   , GeneratorT
--   , initGeneratorState
--   , runGeneratorT
--   , (<<&>>)
--   ) where
--
-- import Universum hiding (show)
--
-- import Hedgehog
-- import Text.Show (show)
--
-- import Lorentz hiding (cast, not)
-- import Morley.Tezos.Crypto (SecretKey)
--
-- import Ligo.BaseDAO.Types
-- import SMT.Model.BaseDAO.Types
-- import Test.Ligo.BaseDAO.Common (ContractType(..))
--
--
-- -- | A type that will be the inputs to the (Haskell) Model.
-- -- This contains a list of entrypoint calls and the `ModelState`.
-- newtype ModelInput cep =
--   ModelInput ([ModelCall cep], ModelState cep)
--   deriving stock Show
--
-- -- | A type needed to pass to `MkModelInput` to get `ModelInput`
-- data ModelInputArg = ModelInputArg
--   { miaGuardianAddr :: Address -- Used in `genPropose`, `genStorage`
--   , miaGovAddr :: Address -- Used in `genPropose`, `genTransferContractTokens`
--   , miaViewContractAddr :: TAddress (MText, Maybe MText) -- Used in registry dao `genLookupRegistryEntrypoint`
--   }
--
-- -- | The main type that will be generated by the generator.
-- -- We cannot generate just the `ModelInput`, since it is not possible get the address of guardian
-- -- and governance contract until they are originated in the nettest.
-- -- As a result, we generate functions that accepts those addresses instead.
-- type MkModelInput cep = ModelInputArg -> ModelInput cep
--
-- -- | Instance Needed by Hedgehog `forall`
-- instance Show (ModelInputArg -> ModelInput cep) where
--   show _ = "<MkModelInput>"
--
-- -- | A type for `genPropose` which is used by registry/treasury dao
-- type MkGenPropose cep =
--      Address
--   -> Address
--   -> Address
--   -> GeneratorT cep (Address -> Address -> (Parameter' cep, Natural, ProposalKey))
--
-- type MkGenCustomCalls cep = GeneratorT cep ([ModelInputArg -> cep])
--
-- -- | A data type that is used to configure the generator, initial storage
-- -- how the SMT behaves. Mostly used by Registry/Treasury SMT.
-- data SmtOption cep = SmtOption
--   { soMkPropose :: MkGenPropose cep
--   , soMkCustomCalls :: MkGenCustomCalls cep
--
--   , soModifyFs :: (FullStorage -> FullStorage)
--     -- ^ Used by `registry/treasury` dao to add their configurations (sExtra, cProposalCheck ..)
--     -- to the generated storage.
--
--   , soContractType :: ContractType
--     -- ^ Track which dao the smt used. Mainly needed to run some pre-cond (sendXtz when registry/treasury)
--
--   , soProposalCheck :: (ProposeParams, ContractExtra) -> ModelT cep ()
--   , soRejectedProposalSlashValue :: (Proposal, ContractExtra) -> ModelT cep Natural
--   , soDecisionLambda :: DecisionLambdaInput -> ModelT cep ([SimpleOperation], ContractExtra, Maybe Address)
--   , soCustomEps :: cep -> ModelT cep ()
--   }
--
-- -- | Generator state, contains commonly used value that shared between generators.
-- data GeneratorState cep = GeneratorState
--   { gsAddresses :: [(Address, SecretKey)]
--   , gsLevel :: Natural
--   , gsMkGenPropose :: MkGenPropose cep
--   , gsMkCustomCalls :: MkGenCustomCalls cep
--   }
--
-- -- | Generator transformer containing `GeneratorState`
-- newtype GeneratorT cep a = GeneratorT
--   { unGeneratorT :: StateT (GeneratorState cep) Gen a
--   } deriving newtype (Functor, Applicative, Monad, MonadState (GeneratorState cep), MonadGen)
--
-- initGeneratorState :: MkGenPropose cep -> GeneratorState cep
-- initGeneratorState mkGenPropose = GeneratorState [] 0 mkGenPropose (pure [])
--
-- runGeneratorT :: GeneratorT cep a -> GeneratorState cep -> Gen a
-- runGeneratorT genAction st = do
--   evalStateT (unGeneratorT genAction) st
--
-- ------------------------------------------------------------------------------------
-- -- Helper
-- ------------------------------------------------------------------------------------
--
-- -- | Fmap twice. Reverse of @<<$>>@
-- (<<&>>) :: (Functor f1, Functor f2) => f1 (f2 a) -> (a -> b) -> f1 (f2 b)
-- (<<&>>) a f =
--   fmap (fmap f) a
