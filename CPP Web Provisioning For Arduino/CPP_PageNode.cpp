/*!
	\class CPP_PageNode
	\brief A class which can be used to model and parse HTML code on arduino devices (or elsewhere).
*/

#include <string>
using std::string;

class CPP_PageNode;

class CPP_PageNode {
	private:
		// The HTML tag for this node
		string tag = "";
		// Mem Ref of child tag
		CPP_PageNode* child_node = nullptr;
		// Mem ref of neighbour tag. (Linked list of elems sharing a parent)
		CPP_PageNode* neighbor_node = nullptr;
		bool is_text_node = false;

	public:

		//! Constructor for a root or standalone node
		/*!
			\param t[] the HTML element or text this node shoudl represent.
			\param text_node a boolean which if true means the parser should not attempt to automatically generate a closing tag.
		*/
		CPP_PageNode(const char t[], bool text_node) {
			tag = t;
			is_text_node = text_node;
		}

		//! Constructor for a HTML node with parent
		/*!
			\param t[] the HTML element or text this node shoudl represent.
			\param text_node a boolean which if true means the parser should not attempt to automatically generate a closing tag.
			\param c a pointer to the parent node/HTML element.
		*/
		CPP_PageNode(const char t[], bool text_node, CPP_PageNode* c) {
			tag = t;
			is_text_node = text_node;
			c->append_child_node(this);
		}

		//! Set text property of a node 
		/*!
			\param s text for the html tag to set. 
		*/
		void set_tag(string s) {
			tag = s;
		}

		//! Get text property of a tag 
		string get_tag() {
			return tag;
		}

		//! Booleans to let user work out where they should put a node in tree 
		bool is_text() { return is_text_node; }
		bool has_child() { return child_node != nullptr; }
		bool has_neighbor() { return neighbor_node != nullptr; }

		//! Gets the child of a node e.g body_node->get_child_node() :  header1_node
		CPP_PageNode* get_child_node() {
			return child_node;
		}

		//! Append a node as a child
		/*!
			\param c a pointer to the node which should be appended as a child of this.
		*/
		void append_child_node(CPP_PageNode* c) {
			if (has_child() == false) {
				child_node = c;
			}
			else {
				get_child_node() ->append_neighbor_node(c);
			}
		}



		//! Gets next element in pseudo linked-list on same level of DOM 
		CPP_PageNode* get_neighbor_node() {
			return neighbor_node;
		}

		//! Appends a neighbor to node provided as param*/
		/*!
			\param n a pointer to the node which should be appended as a neighbor of this.
		*/
		void append_neighbor_node(CPP_PageNode* n) {
			if (has_neighbor() == false) {
				neighbor_node = n;
			}
			else {
				get_neighbor_node() -> append_neighbor_node(n);
			}
		}

		//! Converts the current node and its children/neighbors to a string of html.
		string draw_me_and_my_child() {
			string str = get_tag();
			if (has_child() == true) {
				str.append(get_child_node()->draw_me_and_my_child());

			}

			if (is_text() != true) {
				str.append(tag.insert(1, "/"));
			}

			if (has_neighbor() == true) {
				str.append(get_neighbor_node() -> draw_me_and_my_child());
			}
			return str;
		}
			
		//! Destruction not fully implemented yet. This can be used in the meantime to disassemble a tree.
		void dissassemble(){
			if (has_child() == true) {
				get_child_node() -> dissassemble();
				delete(get_child_node());
			}

			if (has_neighbor() == true) {
				get_neighbor_node() -> dissassemble();
				delete(get_neighbor_node());
			}
		}

};
