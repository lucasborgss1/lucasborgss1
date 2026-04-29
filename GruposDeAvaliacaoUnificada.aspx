<%@ Page Title="Grupos de Avaliação Unificada" Language="C#"
    MasterPageFile="~/Modules/Diario/MasterPage/ClasseMasterPageSlide.master"
    AutoEventWireup="true"
    CodeFile="GruposDeAvaliacaoUnificada.aspx.cs"
    Inherits="Modules_Diario_Professor_Classe_GruposDeAvaliacaoUnificada" %>

<%@ Register Assembly="DevExpress.Web.v18.1" Namespace="DevExpress.Web" TagPrefix="dx" %>
<%@ Register Src="~/ErrorPanel.ascx" TagName="ErrorPanel" TagPrefix="uc" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <style type="text/css">
        .filtros-panel {
            margin-bottom: 10px;
        }
        .grid-titulo {
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 5px;
        }
        .info-grupo {
            background-color: #f0f4ff;
            border: 1px solid #c0cce0;
            border-radius: 4px;
            padding: 8px 12px;
            margin-bottom: 8px;
            font-size: 13px;
        }
        .info-grupo span {
            margin-right: 20px;
        }
        .alerta-notas {
            color: #cc0000;
            font-weight: bold;
        }
        .popup-mensagem {
            padding: 10px 0;
            font-size: 13px;
        }
        .popup-botoes {
            text-align: right;
            margin-top: 10px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <uc:ErrorPanel ID="errorPanel" runat="server" />

    <%-- Hidden fields para persistência dos filtros --%>
    <dx:ASPxHiddenField ID="hfPeriodo" runat="server" ClientInstanceName="hfPeriodo" />
    <dx:ASPxHiddenField ID="hfGrupo" runat="server" ClientInstanceName="hfGrupo" />
    <dx:ASPxHiddenField ID="hfComponente" runat="server" ClientInstanceName="hfComponente" />
    <dx:ASPxHiddenField ID="hfProfessor" runat="server" ClientInstanceName="hfProfessor" />
    <dx:ASPxHiddenField ID="hfGrupoSelecionado" runat="server" ClientInstanceName="hfGrupoSelecionado" />

    <%-- DataSources --%>
    <asp:ObjectDataSource runat="server" ID="dsPeriodoLetivo"
        TypeName="Diario.DataSources.PeriodoLetivoDataSource"
        SelectMethod="GetVigente"
        OnObjectCreating="dsPeriodoLetivo_ObjectCreating" />

    <asp:ObjectDataSource runat="server" ID="dsGrupoFiltro"
        TypeName="Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource"
        SelectMethod="ListarPorPeriodoLetivo"
        OnObjectCreating="dsGrupo_ObjectCreating"
        OnSelecting="dsGrupoFiltro_Selecting" />

    <asp:ObjectDataSource runat="server" ID="dsEtapaGrupo"
        TypeName="Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource"
        SelectMethod="ListarGrupos"
        InsertMethod="SalvarGrupo"
        UpdateMethod="SalvarGrupo"
        DeleteMethod="ExcluirGrupo"
        OnObjectCreating="dsGrupo_ObjectCreating"
        OnSelecting="dsEtapaGrupo_Selecting" />

    <asp:ObjectDataSource runat="server" ID="dsAvaliacoesGrupo"
        TypeName="Diario.DataSources.GrupoDeAvaliacaoUnificadaDataSource"
        SelectMethod="ListarAvaliacoesDoGrupo"
        InsertMethod="SalvarAvaliacaoVinculada"
        DeleteMethod="ExcluirAvaliacaoVinculada"
        OnObjectCreating="dsGrupo_ObjectCreating"
        OnSelecting="dsAvaliacoesGrupo_Selecting" />

    <%-- Painel de Filtros --%>
    <div class="filtros-panel">
        <dx:ASPxFormLayout runat="server" ID="formFiltros" ColCount="2">
            <Items>
                <dx:LayoutItem Caption="Período Letivo" ColSpan="1">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxComboBox runat="server" ID="cbPeriodoLetivo" ClientInstanceName="cbPeriodoLetivo"
                                DataSourceID="dsPeriodoLetivo"
                                TextField="DescricaoCompacta"
                                ValueField="Id"
                                Width="300px"
                                DropDownStyle="DropDown">
                            </dx:ASPxComboBox>
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
                <dx:LayoutItem Caption="" ColSpan="1">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxCheckBox runat="server" ID="chkVigentes" ClientInstanceName="chkVigentes"
                                Text="Listar apenas períodos vigentes"
                                AutoPostBack="true"
                                OnCheckedChanged="chkVigentes_CheckedChanged" />
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
                <dx:LayoutItem Caption="Grupo de Avaliação Unificada" ColSpan="1">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxComboBox runat="server" ID="cbGrupoAvaliacao" ClientInstanceName="cbGrupoAvaliacao"
                                DataSourceID="dsGrupoFiltro"
                                TextField="Descricao"
                                ValueField="IdGrupoAvaliacaoUnificada"
                                Width="300px"
                                DropDownStyle="DropDown">
                                <Items>
                                    <dx:ListEditItem Text="(Todos)" Value="" />
                                </Items>
                            </dx:ASPxComboBox>
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
                <dx:LayoutItem Caption="Componente Curricular" ColSpan="1">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxComboBox runat="server" ID="cbComponente" ClientInstanceName="cbComponente"
                                Width="300px"
                                DropDownStyle="DropDown"
                                EnableCallbackMode="true"
                                CallbackPageSize="20">
                            </dx:ASPxComboBox>
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
                <dx:LayoutItem Caption="Professor Principal" ColSpan="1">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxComboBox runat="server" ID="cbProfessor" ClientInstanceName="cbProfessor"
                                Width="300px"
                                DropDownStyle="DropDown"
                                EnableCallbackMode="true"
                                CallbackPageSize="20">
                            </dx:ASPxComboBox>
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
                <dx:LayoutItem ColSpan="2">
                    <LayoutItemNestedControlCollection>
                        <dx:LayoutItemNestedControl>
                            <dx:ASPxButton runat="server" ID="btnExibir" Text="Exibir" AutoPostBack="false">
                                <ClientSideEvents Click="atualizarGrid" />
                            </dx:ASPxButton>
                        </dx:LayoutItemNestedControl>
                    </LayoutItemNestedControlCollection>
                </dx:LayoutItem>
            </Items>
        </dx:ASPxFormLayout>
    </div>

    <%-- Grid Principal --%>
    <div class="grid-titulo">Grupos de Avaliação Unificada</div>

    <dx:ASPxGridView runat="server" ID="gridGrupos" ClientInstanceName="gridGrupos"
        DataSourceID="dsEtapaGrupo"
        KeyFieldName="IdGrupoAvaliacaoUnificada"
        ClientVisible="false"
        Width="100%"
        OnHtmlRowPrepared="gridGrupos_HtmlRowPrepared"
        OnCustomErrorText="gridGrupos_CustomErrorText"
        OnRowInserting="gridGrupos_RowInserting"
        OnRowUpdating="gridGrupos_RowUpdating"
        OnRowDeleting="gridGrupos_RowDeleting">

        <SettingsEditing Mode="Inline" />
        <SettingsBehavior ConfirmDelete="false" />
        <SettingsText EmptyDataRow="Nenhum registro retornado" />

        <ClientSideEvents
            EndCallback="onGridGruposEndCallback"
            CustomButtonClick="onCustomButtonClick"
            BeginCallback="function(s, e) { if (e.command === 'UPDATEEDIT' || e.command === 'CANCELEDIT') { if (typeof $.fn.dirtyForms !== 'undefined') { $('#aspnetForm').dirtyForms('setClean'); } } }" />

        <Columns>
            <dx:GridViewDataTextColumn FieldName="IdGrupoAvaliacaoUnificada" Visible="false" />
            <dx:GridViewDataTextColumn FieldName="IdPeriodoLetivo" Visible="false" />
            <dx:GridViewDataTextColumn FieldName="IdProfessorPrincipal" Visible="false" />

            <dx:GridViewDataTextColumn FieldName="DescricaoPeriodoLetivo" Caption="Período Letivo" ReadOnly="true">
                <EditFormSettings Visible="False" />
            </dx:GridViewDataTextColumn>

            <dx:GridViewDataTextColumn FieldName="Descricao" Caption="Grupo de Avaliações Unificadas">
                <DataItemTemplate>
                    <a href="javascript:void(0)"
                       onclick='exibirAvaliacoesGrupo(<%# Eval("IdGrupoAvaliacaoUnificada") %>)'>
                        <%# Eval("Descricao") %>
                    </a>
                </DataItemTemplate>
            </dx:GridViewDataTextColumn>

            <dx:GridViewDataTextColumn FieldName="NomeProfessorPrincipal" Caption="Professor Principal" ReadOnly="true" />

            <dx:GridViewDataTextColumn FieldName="ChGrupoCompleto" Caption="Grupo Completo" ReadOnly="true">
                <DataItemTemplate>
                    <%# (string)Eval("ChGrupoCompleto") == "S" ? "Sim" : "Não" %>
                </DataItemTemplate>
            </dx:GridViewDataTextColumn>

            <dx:GridViewDataTextColumn FieldName="EstadoGrupo" Caption="Estado do Grupo" ReadOnly="true" />

            <dx:GridViewCommandColumn ShowNewButtonInHeader="true" ButtonType="Image">
                <NewButton>
                    <Image ToolTip="Novo" />
                </NewButton>
                <EditButton>
                    <Image ToolTip="Editar" />
                </EditButton>
                <DeleteButton>
                    <Image ToolTip="Excluir" />
                </DeleteButton>
            </dx:GridViewCommandColumn>
        </Columns>
    </dx:ASPxGridView>

    <%-- Popup: Avaliações do Grupo --%>
    <dx:ASPxPopupControl runat="server" ID="popupAvaliacoes" ClientInstanceName="popupAvaliacoes"
        Width="1000px"
        Modal="true"
        AllowDragging="true"
        CloseAction="CloseButton"
        ShowCloseButton="true"
        HeaderText="Avaliações do Grupo">
        <ClientSideEvents Shown="popupAvaliacoes_Shown" />
        <ContentCollection>
            <dx:PopupControlContentControl>

                <dx:ASPxCallbackPanel runat="server" ID="callbackPanelAvaliacoes" ClientInstanceName="callbackPanelAvaliacoes"
                    OnCallback="callbackPanelAvaliacoes_Callback"
                    Width="100%">
                    <PanelCollection>
                        <dx:PanelContent>

                            <%-- Cabeçalho informativo do grupo --%>
                            <div class="info-grupo">
                                <span><strong>Grupo:</strong> <asp:Label ID="lblNomeGrupo" runat="server" /></span>
                                <span><strong>Professor Principal:</strong> <asp:Label ID="lblProfessorGrupo" runat="server" /></span>
                                <span><strong>Período Letivo:</strong> <asp:Label ID="lblPeriodoGrupo" runat="server" /></span>
                                <asp:Label ID="lblAlertaNotas" runat="server" CssClass="alerta-notas" Visible="false"
                                    Text="⚠ Existem notas lançadas em avaliações deste grupo." />
                            </div>

                            <%-- DataSource para avaliações no popup --%>
                            <div class="grid-titulo">Avaliações Vinculadas</div>

                            <dx:ASPxGridView runat="server" ID="gvAvaliacoes" ClientInstanceName="gvAvaliacoes"
                                DataSourceID="dsAvaliacoesGrupo"
                                KeyFieldName="IdAvaliacaoVinculadaGrupo"
                                Width="100%"
                                OnCustomErrorText="gvAvaliacoes_CustomErrorText"
                                OnRowInserting="gvAvaliacoes_RowInserting"
                                OnRowDeleting="gvAvaliacoes_RowDeleting"
                                OnHtmlRowPrepared="gvAvaliacoes_HtmlRowPrepared">

                                <SettingsEditing Mode="Inline" />
                                <SettingsBehavior ConfirmDelete="false" />
                                <SettingsText EmptyDataRow="Nenhum registro retornado" />

                                <ClientSideEvents EndCallback="onGvAvaliacoesEndCallback" />

                                <Columns>
                                    <dx:GridViewDataTextColumn FieldName="IdAvaliacaoVinculadaGrupo" Visible="false" />

                                    <dx:GridViewDataComboBoxColumn FieldName="IdClasse" Caption="Classe">
                                        <PropertiesComboBox TextField="NomeClasse" ValueField="IdClasse"
                                            EnableCallbackMode="true" CallbackPageSize="20" />
                                    </dx:GridViewDataComboBoxColumn>

                                    <dx:GridViewDataTextColumn FieldName="TipoAtividadePedagogica" Caption="Tipo Atividade Pedagógica" ReadOnly="true" />

                                    <dx:GridViewDataComboBoxColumn FieldName="IdAvaliacao" Caption="Avaliação">
                                        <PropertiesComboBox TextField="NomeAvaliacao" ValueField="IdAvaliacao"
                                            EnableCallbackMode="true" CallbackPageSize="20" />
                                    </dx:GridViewDataComboBoxColumn>

                                    <dx:GridViewDataTextColumn FieldName="Peso" Caption="Peso" ReadOnly="true">
                                        <EditFormSettings Visible="False" />
                                    </dx:GridViewDataTextColumn>

                                    <dx:GridViewDataTextColumn FieldName="TipoVinculo" Caption="Tipo Vinculação" ReadOnly="true">
                                        <EditFormSettings Visible="False" />
                                    </dx:GridViewDataTextColumn>

                                    <dx:GridViewDataTextColumn FieldName="TemNota" Caption="Tem Nota" ReadOnly="true">
                                        <DataItemTemplate>
                                            <%# (bool)Eval("TemNota") ? "Sim" : "Não" %>
                                        </DataItemTemplate>
                                        <EditFormSettings Visible="False" />
                                    </dx:GridViewDataTextColumn>

                                    <dx:GridViewCommandColumn ShowNewButtonInHeader="true" ButtonType="Image">
                                        <NewButton>
                                            <Image ToolTip="Nova Avaliação" />
                                        </NewButton>
                                        <DeleteButton>
                                            <Image ToolTip="Excluir" />
                                        </DeleteButton>
                                    </dx:GridViewCommandColumn>
                                </Columns>
                            </dx:ASPxGridView>

                            <div style="text-align:right; margin-top:8px;">
                                <dx:ASPxButton runat="server" ID="btnFecharAvaliacoes" Text="Fechar" AutoPostBack="false">
                                    <ClientSideEvents Click="function(s, e) { popupAvaliacoes.Hide(); }" />
                                </dx:ASPxButton>
                            </div>

                        </dx:PanelContent>
                    </PanelCollection>
                </dx:ASPxCallbackPanel>

            </dx:PopupControlContentControl>
        </ContentCollection>
    </dx:ASPxPopupControl>

    <%-- Popup de Confirmação / Aviso (padrão ConfiguracaoMatriculaCalouro) --%>
    <dx:ASPxPopupControl runat="server" ID="popupGridEForm" ClientInstanceName="popupGridEForm"
        Width="400px"
        Modal="true"
        AllowDragging="true"
        CloseAction="CloseButton"
        ShowCloseButton="true"
        HeaderText="Atenção">
        <ContentCollection>
            <dx:PopupControlContentControl>
                <div class="popup-mensagem">
                    <p id="popupMensagemGridEForm">Mensagem...</p>
                </div>
                <div class="popup-botoes">
                    <dx:ASPxButton runat="server" ID="btnConfirmarGridEForm" Text="Sim" ClientVisible="false">
                        <ClientSideEvents Click="confirmarExclusao" />
                    </dx:ASPxButton>
                    <dx:ASPxButton runat="server" ID="btnCancelarGridEForm" Text="Ok">
                        <ClientSideEvents Click="function(s, e) { popupGridEForm.Hide(); }" />
                    </dx:ASPxButton>
                </div>
            </dx:PopupControlContentControl>
        </ContentCollection>
    </dx:ASPxPopupControl>

    <script type="text/javascript">

        var indexExclusao = -1;

        // ----------------------------------------------------------------
        // Configurar popup (modo AVISO ou CONFIRMACAO)
        // ----------------------------------------------------------------
        function configurarPopup(modo) {
            if (modo === "CONFIRMACAO") {
                btnConfirmarGridEForm.SetVisible(true);
                btnCancelarGridEForm.SetText("Não");
            } else {
                btnConfirmarGridEForm.SetVisible(false);
                btnCancelarGridEForm.SetText("Ok");
            }
        }

        // ----------------------------------------------------------------
        // Salvar filtros nos HiddenFields
        // ----------------------------------------------------------------
        function SalvarFiltros() {
            hfPeriodo.Set("Value", cbPeriodoLetivo.GetValue());
            hfGrupo.Set("Value", cbGrupoAvaliacao.GetValue() || "");
            hfComponente.Set("Value", cbComponente.GetValue() || "");
            hfProfessor.Set("Value", cbProfessor.GetValue() || "");
        }

        // ----------------------------------------------------------------
        // Atualizar grid principal ao clicar em Exibir
        // ----------------------------------------------------------------
        function atualizarGrid(s, e) {
            if (cbPeriodoLetivo.GetSelectedIndex() === -1 || cbPeriodoLetivo.GetValue() == null || cbPeriodoLetivo.GetValue() === "") {
                document.getElementById("popupMensagemGridEForm").innerText = "Selecione ao menos o Período Letivo para realizar a pesquisa.";
                configurarPopup("AVISO");
                popupGridEForm.Show();
                return;
            }
            SalvarFiltros();
            gridGrupos.SetVisible(true);
            gridGrupos.Refresh();
        }

        // ----------------------------------------------------------------
        // Abrir popup de avaliações do grupo
        // ----------------------------------------------------------------
        function exibirAvaliacoesGrupo(idGrupo) {
            hfGrupoSelecionado.Set("IdGrupoAvaliacaoUnificada", idGrupo);
            popupAvaliacoes.Show();
        }

        // ----------------------------------------------------------------
        // Ao exibir popup de avaliações: disparar callback para carregar dados
        // ----------------------------------------------------------------
        function popupAvaliacoes_Shown(s, e) {
            var id = hfGrupoSelecionado.Get("IdGrupoAvaliacaoUnificada");
            if (id) {
                callbackPanelAvaliacoes.PerformCallback(id);
                gvAvaliacoes.Refresh();
            }
        }

        // ----------------------------------------------------------------
        // Callback end do grid principal: exibir erros via popup
        // ----------------------------------------------------------------
        function onGridGruposEndCallback(s, e) {
            if (s.cpMensagemErro) {
                document.getElementById("popupMensagemGridEForm").innerText = s.cpMensagemErro;
                configurarPopup("AVISO");
                popupGridEForm.Show();
                s.cpMensagemErro = null;
            }
        }

        // ----------------------------------------------------------------
        // Callback end do grid de avaliações: exibir erros via popup
        // ----------------------------------------------------------------
        function onGvAvaliacoesEndCallback(s, e) {
            if (s.cpMensagemErroAvaliacoes) {
                document.getElementById("popupMensagemGridEForm").innerText = s.cpMensagemErroAvaliacoes;
                configurarPopup("AVISO");
                popupGridEForm.Show();
                s.cpMensagemErroAvaliacoes = null;
            }
        }

        // ----------------------------------------------------------------
        // Interceptar botão de excluir customizado no grid principal
        // ----------------------------------------------------------------
        function onCustomButtonClick(s, e) {
            if (e.buttonID === "btnExcluirGrupo") {
                indexExclusao = e.visibleIndex;
                document.getElementById("popupMensagemGridEForm").innerText = "Deseja realmente excluir este grupo de avaliação unificada?";
                configurarPopup("CONFIRMACAO");
                popupGridEForm.Show();
                e.processOnServer = false;
            }
        }

        // ----------------------------------------------------------------
        // Confirmar exclusão após popup de confirmação
        // ----------------------------------------------------------------
        function confirmarExclusao(s, e) {
            popupGridEForm.Hide();
            if (indexExclusao >= 0) {
                gridGrupos.DeleteRow(indexExclusao);
                indexExclusao = -1;
            }
        }

    </script>

</asp:Content>
