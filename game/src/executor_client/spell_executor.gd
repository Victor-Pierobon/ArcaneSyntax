class_name SpellExecutor
extends Node
## Interface de quem executa feitiços. O jogo depende só desta classe; os testes
## de sistemas que usam feitiços podem trocar a implementação por uma falsa.


## Use com await: var result: SpellResult = await executor.execute(request)
func execute(_request: SpellRequest) -> SpellResult:
	push_error("SpellExecutor.execute() precisa ser implementado pela subclasse")
	return SpellResult.failure("NaoImplementado", "executor sem implementação")
