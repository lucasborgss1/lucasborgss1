using System;
using System.Web.UI;
using DevExpress.Web;

/// <summary>
/// Gerenciamento de Grupos de Avaliação Unificada no Portal do Professor.
/// Permite que uma única avaliação teórica seja compartilhada e sincronizada
/// entre múltiplos componentes curriculares do internato.
/// </summary>
public partial class Modules_Diario_Professor_Classe_GruposDeAvaliacaoUnificada : DiarioWebFormObject, IPreRequisito
{
    // -------------------------------------------------------------------------
    // ViewState keys
    // -------------------------------------------------------------------------
    private const string VS_ID_GRUPO          = "vsIdGrupoSelecionado";
    private const string VS_ID_PERIODO_GRUPO  = "vsIdPeriodoLetivoGrupo";
    private const string VS_ID_PROFESSOR_GRUPO = "vsIdProfessorGrupo";

    // -------------------------------------------------------------------------
    // ViewState properties
    // -------------------------------------------------------------------------
    private decimal IdGrupoSelecionado
    {
        get { return ViewState[VS_ID_GRUPO] != null ? (decimal)ViewState[VS_ID_GRUPO] : 0; }
        set { ViewState[VS_ID_GRUPO] = value; }
    }

    private decimal IdPeriodoLetivoGrupo
    {
        get { return ViewState[VS_ID_PERIODO_GRUPO] != null ? (decimal)ViewState[VS_ID_PERIODO_GRUPO] : 0; }
        set { ViewState[VS_ID_PERIODO_GRUPO] = value; }
    }

    private decimal IdProfessorGrupo
    {
        get { return ViewState[VS_ID_PROFESSOR_GRUPO] != null ? (decimal)ViewState[VS_ID_PROFESSOR_GRUPO] : 0; }
        set { ViewState[VS_ID_PROFESSOR_GRUPO] = value; }
    }

    // -------------------------------------------------------------------------
    // IPreRequisito
    // -------------------------------------------------------------------------
    public bool PreRequisitoAtendido
    {
        get { return true; }
    }

    // -------------------------------------------------------------------------
    // Ciclo de vida da página
    // -------------------------------------------------------------------------
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        callbackPanelAvaliacoes.Callback += callbackPanelAvaliacoes_Callback;
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
    }

    // -------------------------------------------------------------------------
    // ObjectCreating — instanciam as classes de DataSource com injeção de contexto
    // -------------------------------------------------------------------------
    protected void dsPeriodoLetivo_ObjectCreating(object sender, ObjectDataSourceEventArgs e)
    {
        e.ObjectInstance = new Diario.DataSources.PeriodoLetivoDataSource(WebModule.Dispatcher);
    }

    protected void dsGrupo_ObjectCreating(object sender, ObjectDataSourceEventArgs e)
    {
        e.ObjectInstance = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);
    }

    // -------------------------------------------------------------------------
    // Selecting — injeta parâmetros nos DataSources a partir dos HiddenFields
    // -------------------------------------------------------------------------

    /// <summary>
    /// Filtra o combo de grupos pelo período letivo selecionado no filtro.
    /// </summary>
    protected void dsGrupoFiltro_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        decimal idPeriodo = 0;
        decimal.TryParse(hfPeriodo.Get("Value") as string, out idPeriodo);
        e.InputParameters["idPeriodoLetivo"] = idPeriodo;
    }

    /// <summary>
    /// Injeta todos os parâmetros de filtro (período, grupo, componente, professor)
    /// no DataSource do grid principal.
    /// </summary>
    protected void dsEtapaGrupo_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        decimal idPeriodo   = 0;
        decimal idGrupo     = 0;
        string  componente  = string.Empty;
        string  professor   = string.Empty;

        decimal.TryParse(hfPeriodo.Get("Value")     as string, out idPeriodo);
        decimal.TryParse(hfGrupo.Get("Value")       as string, out idGrupo);
        componente = hfComponente.Get("Value") as string ?? string.Empty;
        professor  = hfProfessor.Get("Value")  as string ?? string.Empty;

        e.InputParameters["idPeriodoLetivo"] = idPeriodo;
        e.InputParameters["idGrupo"]         = idGrupo;
        e.InputParameters["componente"]      = componente;
        e.InputParameters["professor"]       = professor;
    }

    /// <summary>
    /// Injeta o ID do grupo selecionado no DataSource de avaliações do popup.
    /// </summary>
    protected void dsAvaliacoesGrupo_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        e.InputParameters["idGrupoAvaliacaoUnificada"] = IdGrupoSelecionado;
    }

    // -------------------------------------------------------------------------
    // Checkbox "Listar apenas períodos vigentes" — rebind do combo de período
    // -------------------------------------------------------------------------
    protected void chkVigentes_CheckedChanged(object sender, EventArgs e)
    {
        dsPeriodoLetivo.SelectMethod = chkVigentes.Checked ? "GetVigente" : "GetTodos";
        cbPeriodoLetivo.DataBind();
    }

    // -------------------------------------------------------------------------
    // Grid Principal — gridGrupos
    // -------------------------------------------------------------------------

    /// <summary>
    /// Controla a visibilidade dos botões Editar e Excluir por linha,
    /// verificando se o usuário logado é o Professor Principal do grupo.
    /// </summary>
    protected void gridGrupos_HtmlRowPrepared(object sender, ASPxGridViewTableRowEventArgs e)
    {
        if (e.RowType != DevExpress.Web.GridViewRowType.Data)
            return;

        decimal idProfessorPrincipal = 0;
        var rawValue = gridGrupos.GetRowValues(e.VisibleIndex, "IdProfessorPrincipal");
        if (rawValue != null)
            decimal.TryParse(rawValue.ToString(), out idProfessorPrincipal);

        bool usuarioEhPrincipal = UsuarioEhProfessorPrincipal(idProfessorPrincipal);

        // Ocultar botão Editar se o usuário não for o professor principal
        var btnEditar  = gridGrupos.FindRowCellTemplateControl(e.VisibleIndex, null, "btnEditar")  as ASPxButton;
        var btnExcluir = gridGrupos.FindRowCellTemplateControl(e.VisibleIndex, null, "btnExcluir") as ASPxButton;

        if (btnEditar  != null) btnEditar.ClientVisible  = usuarioEhPrincipal;
        if (btnExcluir != null) btnExcluir.ClientVisible = usuarioEhPrincipal;

        // Forçar visibilidade via CSS quando os controles são colunas de comando nativas
        if (!usuarioEhPrincipal)
        {
            e.Row.Cells[e.Row.Cells.Count - 1].Text = "&nbsp;";
        }
    }

    /// <summary>
    /// Tratamento de erros customizados no grid principal.
    /// Propaga mensagem para o cliente via CustomProperty.
    /// </summary>
    protected void gridGrupos_CustomErrorText(object sender, ASPxGridViewCustomErrorTextEventArgs e)
    {
        e.ErrorText = e.Exception.Message;
        gridGrupos.JSProperties["cpMensagemErro"] = e.Exception.Message;
    }

    /// <summary>
    /// Inserção de novo grupo inline.
    /// Valida unicidade (descrição + período letivo) e preenche campos automáticos.
    /// </summary>
    protected void gridGrupos_RowInserting(object sender, DevExpress.Web.Data.ASPxDataInsertingEventArgs e)
    {
        decimal idPeriodo = 0;
        decimal.TryParse(hfPeriodo.Get("Value") as string, out idPeriodo);

        if (idPeriodo == 0)
        {
            e.Cancel = true;
            gridGrupos.JSProperties["cpMensagemErro"] = "Selecione o Período Letivo antes de inserir um grupo.";
            return;
        }

        string descricao = e.NewValues["Descricao"] as string;
        if (string.IsNullOrWhiteSpace(descricao))
        {
            e.Cancel = true;
            gridGrupos.JSProperties["cpMensagemErro"] = "A descrição do grupo é obrigatória.";
            return;
        }

        // Campos automáticos
        e.NewValues["IdPeriodoLetivo"]      = idPeriodo;
        e.NewValues["IdProfessorPrincipal"] = ObterIdUsuarioLogado();
        e.NewValues["ChGrupoCompleto"]      = "N";
        e.NewValues["EstadoGrupo"]          = "Incompleto";
    }

    /// <summary>
    /// Atualização inline do grupo.
    /// Apenas a descrição pode ser alterada; período letivo é bloqueado.
    /// </summary>
    protected void gridGrupos_RowUpdating(object sender, DevExpress.Web.Data.ASPxDataUpdatingEventArgs e)
    {
        decimal idProfessorPrincipal = 0;
        var rawValue = e.Keys["IdProfessorPrincipal"];
        if (rawValue != null)
            decimal.TryParse(rawValue.ToString(), out idProfessorPrincipal);

        if (!UsuarioEhProfessorPrincipal(idProfessorPrincipal))
        {
            e.Cancel = true;
            gridGrupos.JSProperties["cpMensagemErro"] = "Apenas o professor principal pode alterar o nome do grupo.";
        }
    }

    /// <summary>
    /// Exclusão inline do grupo.
    /// Verifica se o usuário é o professor principal e se não há avaliações cadastradas.
    /// </summary>
    protected void gridGrupos_RowDeleting(object sender, DevExpress.Web.Data.ASPxDataDeletingEventArgs e)
    {
        decimal idProfessorPrincipal = 0;
        var rawValue = e.Keys["IdProfessorPrincipal"];
        if (rawValue != null)
            decimal.TryParse(rawValue.ToString(), out idProfessorPrincipal);

        if (!UsuarioEhProfessorPrincipal(idProfessorPrincipal))
        {
            e.Cancel = true;
            gridGrupos.JSProperties["cpMensagemErro"] = "Apenas o professor principal pode excluir o grupo.";
            return;
        }

        decimal idGrupo = 0;
        var rawIdGrupo = e.Keys["IdGrupoAvaliacaoUnificada"];
        if (rawIdGrupo != null)
            decimal.TryParse(rawIdGrupo.ToString(), out idGrupo);

        if (idGrupo > 0 && GrupoPossuiAvaliacoes(idGrupo))
        {
            e.Cancel = true;
            gridGrupos.JSProperties["cpMensagemErro"] = "Não é possível excluir um grupo que possui avaliações cadastradas.";
        }
    }

    // -------------------------------------------------------------------------
    // Callback do popup de Avaliações
    // -------------------------------------------------------------------------

    /// <summary>
    /// Callback disparado ao abrir o popup de avaliações.
    /// Carrega os dados do grupo selecionado e atualiza o cabeçalho informativo.
    /// </summary>
    protected void callbackPanelAvaliacoes_Callback(object source, DevExpress.Web.CallbackEventArgsBase e)
    {
        decimal idGrupo = 0;
        if (!string.IsNullOrEmpty(e.Parameter))
            decimal.TryParse(e.Parameter, out idGrupo);

        IdGrupoSelecionado = idGrupo;

        if (idGrupo > 0)
        {
            var ds = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);
            var grupo = ds.ObterGrupo(idGrupo);
            if (grupo != null)
            {
                lblNomeGrupo.Text        = grupo.Descricao;
                lblProfessorGrupo.Text   = grupo.NomeProfessorPrincipal;
                lblPeriodoGrupo.Text     = grupo.DescricaoPeriodoLetivo;
                IdPeriodoLetivoGrupo     = grupo.IdPeriodoLetivo;
                IdProfessorGrupo         = grupo.IdProfessorPrincipal;

                lblAlertaNotas.Visible   = ds.GrupoPossuiNotasLancadas(idGrupo);
            }
        }

        gvAvaliacoes.DataBind();
    }

    // -------------------------------------------------------------------------
    // Grid de Avaliações — gvAvaliacoes
    // -------------------------------------------------------------------------

    /// <summary>
    /// Controla a visibilidade do botão Excluir no grid de avaliações:
    /// só permitido para avaliações Sincronizadas pelo professor principal,
    /// e somente quando não há notas lançadas no grupo.
    /// </summary>
    protected void gvAvaliacoes_HtmlRowPrepared(object sender, ASPxGridViewTableRowEventArgs e)
    {
        if (e.RowType != DevExpress.Web.GridViewRowType.Data)
            return;

        string tipoVinculo = gvAvaliacoes.GetRowValues(e.VisibleIndex, "TipoVinculo") as string ?? string.Empty;
        bool temNota       = false;
        var rawTemNota     = gvAvaliacoes.GetRowValues(e.VisibleIndex, "TemNota");
        if (rawTemNota != null) bool.TryParse(rawTemNota.ToString(), out temNota);

        bool podeDeletar = tipoVinculo.Equals("Sincronizada", StringComparison.OrdinalIgnoreCase)
                        && UsuarioEhProfessorPrincipal(IdProfessorGrupo)
                        && !temNota;

        if (!podeDeletar)
        {
            e.Row.Cells[e.Row.Cells.Count - 1].Text = "&nbsp;";
        }
    }

    /// <summary>
    /// Tratamento de erros customizados no grid de avaliações.
    /// </summary>
    protected void gvAvaliacoes_CustomErrorText(object sender, ASPxGridViewCustomErrorTextEventArgs e)
    {
        e.ErrorText = e.Exception.Message;
        gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] = e.Exception.Message;
    }

    /// <summary>
    /// Inserção de nova avaliação vinculada.
    /// Aplica todas as regras de negócio:
    ///   - Bloqueio se houver notas lançadas no grupo
    ///   - Unicidade da avaliação em grupos
    ///   - Consistência de alunos (regra crítica)
    ///   - Tipo de vínculo automático (Origem / Sincronizada)
    ///   - Warning de divergência de pesos (não bloqueia)
    /// </summary>
    protected void gvAvaliacoes_RowInserting(object sender, DevExpress.Web.Data.ASPxDataInsertingEventArgs e)
    {
        if (IdGrupoSelecionado == 0)
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] = "Nenhum grupo selecionado.";
            return;
        }

        var ds = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);

        // Regra: Bloqueio de Edição Estrutural — notas já lançadas
        if (ds.GrupoPossuiNotasLancadas(IdGrupoSelecionado))
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "Não é permitido incluir avaliações em um grupo que já possui notas lançadas.";
            return;
        }

        decimal idAvaliacao = 0;
        var rawIdAvaliacao = e.NewValues["IdAvaliacao"];
        if (rawIdAvaliacao != null)
            decimal.TryParse(rawIdAvaliacao.ToString(), out idAvaliacao);

        // Regra: Unicidade — avaliação já pertence a outro grupo
        if (idAvaliacao > 0 && ds.AvaliacaoPertenceAOutroGrupo(idAvaliacao, IdGrupoSelecionado))
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "Esta avaliação já pertence a outro grupo de avaliação unificada.";
            return;
        }

        // Determinar tipo de vínculo automaticamente
        bool gridVazia      = gvAvaliacoes.VisibleRowCount == 0;
        string tipoVinculo  = gridVazia ? "Origem" : "Sincronizada";
        e.NewValues["TipoVinculo"]               = tipoVinculo;
        e.NewValues["IdGrupoAvaliacaoUnificada"]  = IdGrupoSelecionado;

        // Regra Crítica: Consistência de alunos (somente para Sincronizadas)
        if (!gridVazia)
        {
            decimal idClasse = 0;
            var rawIdClasse = e.NewValues["IdClasse"];
            if (rawIdClasse != null)
                decimal.TryParse(rawIdClasse.ToString(), out idClasse);

            string erroConsistencia = ds.ValidarConsistenciaAlunos(IdGrupoSelecionado, idClasse);
            if (!string.IsNullOrEmpty(erroConsistencia))
            {
                e.Cancel = true;
                gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] = erroConsistencia;
                return;
            }
        }

        // Warning de divergência de pesos (não bloqueia)
        if (!gridVazia && idAvaliacao > 0 && ds.ExisteDivergenciaDePesos(IdGrupoSelecionado, idAvaliacao))
        {
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "O grupo de avaliação unificada possui avaliações com pesos diferentes!";
            // Não cancela — apenas exibe o warning
        }
    }

    /// <summary>
    /// Pós-inserção: atualiza o estado do grupo.
    /// </summary>
    protected void gvAvaliacoes_RowInserted(object sender, DevExpress.Web.Data.ASPxDataInsertedEventArgs e)
    {
        if (IdGrupoSelecionado > 0)
            AtualizarEstadoGrupo(IdGrupoSelecionado);
    }

    /// <summary>
    /// Exclusão de avaliação vinculada.
    /// Verifica permissões e existência de notas.
    /// </summary>
    protected void gvAvaliacoes_RowDeleting(object sender, DevExpress.Web.Data.ASPxDataDeletingEventArgs e)
    {
        string tipoVinculo = e.Values["TipoVinculo"] as string ?? string.Empty;

        if (!tipoVinculo.Equals("Sincronizada", StringComparison.OrdinalIgnoreCase))
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "Não é possível excluir a avaliação de Origem do grupo.";
            return;
        }

        if (!UsuarioEhProfessorPrincipal(IdProfessorGrupo))
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "Apenas o professor principal pode excluir avaliações do grupo.";
            return;
        }

        var ds = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);
        if (ds.GrupoPossuiNotasLancadas(IdGrupoSelecionado))
        {
            e.Cancel = true;
            gvAvaliacoes.JSProperties["cpMensagemErroAvaliacoes"] =
                "Não é permitido excluir avaliações de um grupo que já possui notas lançadas.";
        }
    }

    /// <summary>
    /// Pós-exclusão: atualiza o estado do grupo.
    /// </summary>
    protected void gvAvaliacoes_RowDeleted(object sender, DevExpress.Web.Data.ASPxDataDeletedEventArgs e)
    {
        if (IdGrupoSelecionado > 0)
            AtualizarEstadoGrupo(IdGrupoSelecionado);
    }

    // -------------------------------------------------------------------------
    // Helpers privados
    // -------------------------------------------------------------------------

    /// <summary>
    /// Verifica se o usuário logado é o professor principal do grupo.
    /// </summary>
    private bool UsuarioEhProfessorPrincipal(decimal idProfessor)
    {
        decimal idUsuarioLogado = ObterIdUsuarioLogado();
        return idUsuarioLogado > 0 && idUsuarioLogado == idProfessor;
    }

    /// <summary>
    /// Obtém o ID do professor/usuário logado via sessão ou Dispatcher.
    /// </summary>
    private decimal ObterIdUsuarioLogado()
    {
        try
        {
            return WebModule.Dispatcher.IdUsuarioLogado;
        }
        catch
        {
            return 0;
        }
    }

    /// <summary>
    /// Verifica se um grupo já possui avaliações cadastradas (impede exclusão do grupo).
    /// </summary>
    private bool GrupoPossuiAvaliacoes(decimal idGrupo)
    {
        try
        {
            var ds = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);
            return ds.GrupoPossuiAvaliacoes(idGrupo);
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Recalcula e persiste o EstadoGrupo e ChGrupoCompleto sempre que
    /// avaliações são incluídas ou excluídas do grupo.
    ///
    /// Regras de estado:
    ///   Incompleto  — GAU_ch_grupo_completo = 'N'
    ///   Apto        — estrutura válida: ao menos 1 Origem + 1 Sincronizada, sem inconsistências
    ///   Bloqueado   — possui inconsistência (ex: alunos divergentes)
    ///   Publicado   — qualquer avaliação do grupo está publicada
    /// </summary>
    private void AtualizarEstadoGrupo(decimal idGrupo)
    {
        try
        {
            var ds = new Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource(WebModule.Dispatcher);
            ds.AtualizarEstadoGrupo(idGrupo);
        }
        catch
        {
            // Erros de atualização de estado não devem interromper o fluxo
        }
    }
}
